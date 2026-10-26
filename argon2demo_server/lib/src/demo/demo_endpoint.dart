import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'hash_compare.dart';

/// Public demo endpoint. Call as `client.demo.hash()`.
///
/// Also exposed as HTTP `POST|GET /demo/hash` via [DemoHashRoute] on the web
/// server (preferred for curl / the tiny UI). RPC always runs both paths.
class DemoEndpoint extends Endpoint {
  /// Hash the fixed demo password twice (PointyCastle vs native).
  /// Returns durations only. Throws when the in-flight gate is full.
  Future<HashCompareResult> hash(Session session) async {
    final result = await HashCompare.run(impl: HashImpl.both);
    return HashCompareResult(
      pointycastleMs: result.pointycastleMs ?? 0,
      nativeMs: result.nativeMs ?? 0,
      ratio: result.ratio ?? 0,
      memoryKiB: kMemoryKiB,
      iterations: kIterations,
      parallelism: kParallelism,
    );
  }
}
