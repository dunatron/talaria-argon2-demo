import 'dart:io';

import 'package:serverpod_argon2/serverpod_argon2.dart';
import 'package:talaria_serverpod/talaria_serverpod.dart';

import 'src/cache_busting.dart';
import 'src/generated/serverpod.dart';
import 'src/web/routes/demo_hash_route.dart';
import 'src/web/routes/root.dart';

/// Thin Argon2 compare demo — PointyCastle vs serverpod_argon2 under Talaria.
void run(List<String> args) async {
  final dashboardUrl = Platform.environment['TALARIA_DASHBOARD_URL'] ??
      'https://one.newtalaria.com';
  final apiKey = (Platform.environment['TALARIA_API_KEY'] ?? '').trim();

  final pod = Serverpod(
    args,
    databaseInterceptor: TalariaServerpod.interceptDatabase,
    experimentalFeatures: ExperimentalFeatures(
      diagnosticEventHandlers: [
        AsEventHandler<ExceptionEvent>((event, {required space, required context}) {
          TalariaServerpod.handleExceptionEvent(event);
        }),
      ],
    ),
  );

  if (apiKey.isNotEmpty) {
    await TalariaServerpod.init(
      TalariaOptions(
        dsn: Platform.environment['TALARIA_DSN'] ??
            'https://ingest.newtalaria.com',
        apiKey: apiKey,
        release: Platform.environment['TALARIA_RELEASE'] ?? 'argon2-demo',
        minLevel: SeverityLevel.warning,
        tags: {'service': 'argon2-demo'},
      ),
    );
    TalariaServerpod.attach(pod);
    stdout.writeln('argon2-demo: Talaria attached (release='
        '${Platform.environment['TALARIA_RELEASE'] ?? 'argon2-demo'})');
  } else {
    stderr.writeln(
      'argon2-demo: TALARIA_API_KEY unset — timings work, spans not ingested. '
      'Set tal_live_… from Project settings → Client keys for waterfalls.',
    );
  }

  pod.webServer.addRoute(RootRoute(dashboardUrl: dashboardUrl), '/');
  pod.webServer.addRoute(RootRoute(dashboardUrl: dashboardUrl), '/index.html');
  pod.webServer.addRoute(DemoHashRoute(), '/demo/hash');
  pod.webServer.addRoute(
    StaticRoute.withCacheBusting(cacheBustingConfig),
    cacheBustingConfig.mountPrefix,
  );

  // Fail-fast if native assets were omitted (`dart compile exe` mistake).
  try {
    await Argon2.load();
    stdout.writeln('argon2-demo: native Argon2 loaded OK');
  } catch (e) {
    stderr.writeln(
      'argon2-demo: WARNING native Argon2 failed to load: $e\n'
      'Build the server with `dart build cli` so native assets are included.',
    );
  }

  await pod.start();
}
