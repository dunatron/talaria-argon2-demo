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
import 'dart:async' as _ida;
import 'package:argon2demo_client/src/protocol/demo/hash_compare_result.dart'
    as _ilzwon7l;
import 'package:http/http.dart' as _i85jenna;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'protocol.dart' as _il2as5qe;

/// Public demo endpoint. Call as `client.demo.hash()`.
///
/// Also exposed as HTTP `POST|GET /demo/hash` via [DemoHashRoute] on the web
/// server (preferred for curl / the tiny UI).
/// {@category Endpoint}
class EndpointDemo extends _isc.EndpointRef {
  EndpointDemo(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'demo';

  /// Hash the fixed demo password twice (PointyCastle vs native).
  /// Returns durations only. Throws when the in-flight gate is full.
  _ida.Future<_ilzwon7l.HashCompareResult> hash() =>
      caller.callServerEndpoint<_ilzwon7l.HashCompareResult>(
        'demo',
        'hash',
        {},
      );
}

class Client extends _isc.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _isc.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_isc.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i85jenna.Client? httpClientOverride,
  }) : super(
         host,
         _il2as5qe.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    demo = EndpointDemo(this);
  }

  late final EndpointDemo demo;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {'demo': demo};

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {};
}
