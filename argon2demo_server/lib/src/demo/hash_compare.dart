import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:pointycastle/key_derivators/api.dart' as pc;
import 'package:pointycastle/key_derivators/argon2.dart';
import 'package:serverpod_argon2/serverpod_argon2.dart' as native;
import 'package:talaria/talaria.dart';

/// Fixed fake password — never accept client-supplied secrets.
const kDemoPassword = 'demo-password-not-secret';

/// Fixed salt so both paths hash the same material (fair compare).
final Uint8List kDemoSalt = Uint8List.fromList(
  utf8.encode('talaria-a2-salt'), // 16 bytes
);

/// OWASP password-storage Argon2id params (Serverpod Email IDP).
const kMemoryKiB = 19456;
const kIterations = 2;
const kParallelism = 1;
const kHashLength = 32;

/// Hard cap on concurrent password-grade hashes (DoS guard).
const kMaxInFlightHashes = 1;

/// Which Argon2 path(s) to run under Talaria INTERNAL spans.
enum HashImpl {
  pointycastle,
  native,
  both;

  static HashImpl parse(String? raw) {
    switch ((raw ?? 'both').trim().toLowerCase()) {
      case 'pointycastle':
      case 'pc':
      case 'slow':
        return HashImpl.pointycastle;
      case 'native':
      case 'fast':
      case 'serverpod_argon2':
        return HashImpl.native;
      case 'both':
      case 'compare':
      case 'all':
      case '':
        return HashImpl.both;
      default:
        throw FormatException(
          'Unknown impl "$raw". Use pointycastle, native, or both.',
        );
    }
  }

  String get wire => name;
}

/// Thrown when the in-flight semaphore is full.
class HashBusyException implements Exception {
  @override
  String toString() => 'HashBusyException: too many in-flight hashes';
}

/// Side-by-side PointyCastle (pre-4.0.3) vs serverpod_argon2 (post) timings.
class HashCompare {
  HashCompare._();

  static final _gate = _InFlightGate(kMaxInFlightHashes);

  /// Run one or both hashes under Talaria INTERNAL spans.
  /// Throws [HashBusyException] when [kMaxInFlightHashes] is already in use.
  static Future<
    ({
      HashImpl impl,
      int? pointycastleMs,
      int? nativeMs,
      double? ratio,
    })
  >
  run({HashImpl impl = HashImpl.both}) async {
    if (!_gate.tryAcquire()) {
      throw HashBusyException();
    }
    try {
      final password = utf8.encode(kDemoPassword);
      final salt = Uint8List.fromList(kDemoSalt);

      int? pointycastleMs;
      int? nativeMs;

      if (impl == HashImpl.pointycastle || impl == HashImpl.both) {
        pointycastleMs = await _timedSpan(
          'auth.passwordHash.pointycastle',
          () => Isolate.run(() => _hashPointycastle(password, salt)),
        );
      }

      if (impl == HashImpl.native || impl == HashImpl.both) {
        nativeMs = await _timedSpan(
          'auth.passwordHash.native',
          () => Isolate.run(() => _hashNative(password, salt)),
        );
      }

      double? ratio;
      if (pointycastleMs != null && nativeMs != null) {
        ratio = nativeMs == 0
            ? (pointycastleMs == 0 ? 1.0 : pointycastleMs.toDouble())
            : pointycastleMs / nativeMs;
      }

      return (
        impl: impl,
        pointycastleMs: pointycastleMs,
        nativeMs: nativeMs,
        ratio: ratio,
      );
    } finally {
      _gate.release();
    }
  }

  static Future<int> _timedSpan(
    String name,
    Future<void> Function() body,
  ) async {
    // NoOp when TALARIA_API_KEY was unset at boot, or tracing still off.
    final Span span = Talaria.getClient() != null
        ? Talaria.startSpan(name, kind: SpanKind.internal)
        : const NoOpSpan();
    final sw = Stopwatch()..start();
    try {
      await body();
      span.setStatus(SpanStatus.ok);
    } catch (e) {
      span.markError(message: e.toString());
      rethrow;
    } finally {
      sw.stop();
      span.finish();
    }
    return sw.elapsedMilliseconds;
  }

  static Uint8List _hashPointycastle(List<int> password, Uint8List salt) {
    final parameters = pc.Argon2Parameters(
      pc.Argon2Parameters.ARGON2_id,
      salt,
      desiredKeyLength: kHashLength,
      lanes: kParallelism,
      memory: kMemoryKiB,
      iterations: kIterations,
    );
    final generator = Argon2BytesGenerator()..init(parameters);
    return generator.process(Uint8List.fromList(password));
  }

  static Future<Uint8List> _hashNative(
    List<int> password,
    Uint8List salt,
  ) async {
    final native.Argon2 argon2;
    try {
      argon2 = await native.Argon2.load();
    } on ArgumentError catch (e) {
      throw StateError(
        'Native Argon2 library could not be loaded. Build with '
        '`dart build cli` (not `dart compile exe`). ($e)',
      );
    }
    return argon2.deriveKey(
      password: password,
      salt: salt,
      parameters: const native.Argon2Parameters(
        iterations: kIterations,
        memoryKiB: kMemoryKiB,
        parallelism: kParallelism,
        hashLength: kHashLength,
      ),
    );
  }
}

class _InFlightGate {
  _InFlightGate(this.max);
  final int max;
  int _current = 0;

  bool tryAcquire() {
    if (_current >= max) return false;
    _current++;
    return true;
  }

  void release() {
    if (_current > 0) _current--;
  }
}
