import 'dart:io';

import 'package:serverpod_argon2/serverpod_argon2.dart';
import 'package:talaria_serverpod/talaria_serverpod.dart';

import 'src/cache_busting.dart';
import 'src/generated/serverpod.dart';
import 'src/web/routes/demo_hash_route.dart';
import 'src/web/routes/root.dart';

/// Thin Argon2 compare demo — PointyCastle vs serverpod_argon2 under Talaria.
void run(List<String> args) async {
  final dashboardUrl =
      Platform.environment['TALARIA_DASHBOARD_URL'] ??
      'https://one.newtalaria.com';
  final apiKey = (Platform.environment['TALARIA_API_KEY'] ?? '').trim();
  // Empty means "derive from the key's cell". Only TALARIA_URL overrides that.
  final ingestUrl = (Platform.environment['TALARIA_URL'] ?? '').trim();
  final release = (Platform.environment['TALARIA_RELEASE'] ?? '').trim();
  final commitSha = (Platform.environment['TALARIA_COMMIT_SHA'] ?? '').trim();

  final pod = Serverpod(
    args,
    databaseInterceptor: TalariaServerpod.interceptDatabase,
    experimentalFeatures: ExperimentalFeatures(
      diagnosticEventHandlers: [
        AsEventHandler<ExceptionEvent>((
          event, {
          required space,
          required context,
        }) {
          TalariaServerpod.handleExceptionEvent(event);
        }),
      ],
    ),
  );

  if (apiKey.isNotEmpty) {
    await TalariaServerpod.init(
      TalariaOptions(
        apiKey: apiKey,
        url: ingestUrl.isEmpty ? null : ingestUrl,
        release: release.isEmpty ? 'argon2-demo' : release,
        commitSha: commitSha.isEmpty ? null : commitSha,
        minLevel: SeverityLevel.warning,
        tags: {'service': 'argon2-demo'},
      ),
    );
    TalariaServerpod.attach(pod);
    final attachedRelease = release.isEmpty ? 'argon2-demo' : release;
    stdout.writeln(
      'argon2-demo: Talaria attached (release=$attachedRelease)',
    );
  } else {
    stderr.writeln(
      'argon2-demo: TALARIA_API_KEY unset — timings work, spans not ingested. '
      'Set a tal_sk_… secret key from Project settings → Client keys '
      'for waterfalls.',
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
