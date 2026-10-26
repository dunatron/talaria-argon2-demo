/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// Result of a PointyCastle vs native Argon2id compare.
/// Durations only — never hash bytes.
abstract class HashCompareResult
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  HashCompareResult._({
    required this.pointycastleMs,
    required this.nativeMs,
    required this.ratio,
    required this.memoryKiB,
    required this.iterations,
    required this.parallelism,
  });

  factory HashCompareResult({
    required int pointycastleMs,
    required int nativeMs,
    required double ratio,
    required int memoryKiB,
    required int iterations,
    required int parallelism,
  }) = _HashCompareResultImpl;

  factory HashCompareResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return HashCompareResult(
      pointycastleMs: jsonSerialization['pointycastleMs'] as int,
      nativeMs: jsonSerialization['nativeMs'] as int,
      ratio: (jsonSerialization['ratio'] as num).toDouble(),
      memoryKiB: jsonSerialization['memoryKiB'] as int,
      iterations: jsonSerialization['iterations'] as int,
      parallelism: jsonSerialization['parallelism'] as int,
    );
  }

  int pointycastleMs;

  int nativeMs;

  double ratio;

  int memoryKiB;

  int iterations;

  int parallelism;

  /// Returns a shallow copy of this [HashCompareResult]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  HashCompareResult copyWith({
    int? pointycastleMs,
    int? nativeMs,
    double? ratio,
    int? memoryKiB,
    int? iterations,
    int? parallelism,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'HashCompareResult',
      'pointycastleMs': pointycastleMs,
      'nativeMs': nativeMs,
      'ratio': ratio,
      'memoryKiB': memoryKiB,
      'iterations': iterations,
      'parallelism': parallelism,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'HashCompareResult',
      'pointycastleMs': pointycastleMs,
      'nativeMs': nativeMs,
      'ratio': ratio,
      'memoryKiB': memoryKiB,
      'iterations': iterations,
      'parallelism': parallelism,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _HashCompareResultImpl extends HashCompareResult {
  _HashCompareResultImpl({
    required int pointycastleMs,
    required int nativeMs,
    required double ratio,
    required int memoryKiB,
    required int iterations,
    required int parallelism,
  }) : super._(
         pointycastleMs: pointycastleMs,
         nativeMs: nativeMs,
         ratio: ratio,
         memoryKiB: memoryKiB,
         iterations: iterations,
         parallelism: parallelism,
       );

  /// Returns a shallow copy of this [HashCompareResult]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  HashCompareResult copyWith({
    int? pointycastleMs,
    int? nativeMs,
    double? ratio,
    int? memoryKiB,
    int? iterations,
    int? parallelism,
  }) {
    return HashCompareResult(
      pointycastleMs: pointycastleMs ?? this.pointycastleMs,
      nativeMs: nativeMs ?? this.nativeMs,
      ratio: ratio ?? this.ratio,
      memoryKiB: memoryKiB ?? this.memoryKiB,
      iterations: iterations ?? this.iterations,
      parallelism: parallelism ?? this.parallelism,
    );
  }
}
