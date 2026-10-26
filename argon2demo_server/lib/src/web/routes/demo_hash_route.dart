import 'dart:async';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:talaria/talaria.dart';

import '../../demo/hash_compare.dart';

/// `GET|POST /demo/hash` — JSON timings. Optional `impl=pointycastle|native|both`.
/// Rate-limited to 1 in-flight hash across all impls.
class DemoHashRoute extends Route {
  DemoHashRoute() : super(methods: {Method.get, Method.post}, path: '/');

  @override
  Future<Result> handleCall(Session session, Request request) async {
    try {
      final impl = HashImpl.parse(
        request.url.queryParameters['impl'] ??
            request.url.queryParameters['path'],
      );
      final result = await HashCompare.run(impl: impl);
      final body = jsonEncode({
        'impl': result.impl.wire,
        'pointycastleMs': result.pointycastleMs,
        'nativeMs': result.nativeMs,
        'ratio': result.ratio,
        'memoryKiB': kMemoryKiB,
        'iterations': kIterations,
        'parallelism': kParallelism,
        'params': 'argon2id m=$kMemoryKiB t=$kIterations p=$kParallelism',
        'note':
            'Fixed fake password only. Never returns hash bytes. '
            'Spans: auth.passwordHash.pointycastle / auth.passwordHash.native. '
            'Pass ?impl=pointycastle|native|both',
      });
      return Response.ok(
        body: Body.fromString(body, mimeType: MimeType.json),
      );
    } on FormatException catch (e) {
      return Response(
        400,
        body: Body.fromString(
          jsonEncode({
            'error': 'bad_request',
            'message': e.message,
          }),
          mimeType: MimeType.json,
        ),
      );
    } on HashBusyException {
      return Response(
        429,
        body: Body.fromString(
          jsonEncode({
            'error': 'too_many_requests',
            'message': 'Rate limited — try again in a few seconds.',
          }),
          mimeType: MimeType.json,
        ),
      );
    } catch (e, st) {
      // Surface in Talaria Errors when a key is present; never leak to HTML.
      final client = Talaria.getClient();
      if (client != null) {
        unawaited(client.captureException(e, stackTrace: st));
      }
      return Response.internalServerError(
        body: Body.fromString(
          jsonEncode({'error': 'internal', 'message': e.toString()}),
          mimeType: MimeType.json,
        ),
      );
    }
  }
}
