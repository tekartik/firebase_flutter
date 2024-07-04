import 'package:tekartik_firebase/firebase.dart';

/// Interface representing an HttpsCallable instance's options,
class FirebaseFunctionsCallableOptions {
  /// Constructs a new [HttpsCallableOptions] instance with given `timeout` & `limitedUseAppCheckToken`
  /// Defaults [timeout] to 60 seconds.
  /// Defaults [limitedUseAppCheckToken] to `false`
  FirebaseFunctionsCallableOptions(
      {this.timeout = const Duration(seconds: 60),
      this.limitedUseAppCheckToken = false});

  /// Returns the timeout for this instance
  Duration timeout;

  /// Sets whether or not to use limited-use App Check tokens when invoking the associated function.
  bool limitedUseAppCheckToken;

  @override
  String toString() =>
      'FirebaseFunctionsCallableOptions(timeout: $timeout${limitedUseAppCheckToken == true ? ', limitedUseAppCheckToken: $limitedUseAppCheckToken' : ''})';
}

/// Firebase functions call
abstract class FirebaseFunctionsCall {
  /// A reference to the Callable HTTPS trigger with the given name.
  ///
  /// Should be the name of the Callable function in Firebase
  FirebaseFunctionsCallable callable(
    String name, {
    FirebaseFunctionsCallableOptions? options,
  });
}

/// A reference to a particular Callable HTTPS trigger in Cloud Functions.
abstract class FirebaseFunctionsCallable {
  /// Executes this Callable HTTPS trigger asynchronously.
  ///
  /// The data passed into the trigger can be any of the following types:
  ///
  /// `null`
  /// `String`
  /// `num`
  /// [List], where the contained objects are also one of these types.
  /// [Map], where the values are also one of these types.
  ///
  /// The request to the Cloud Functions backend made by this method
  /// automatically includes a Firebase Instance ID token to identify the app
  /// instance. If a user is logged in with Firebase Auth, an auth ID token for
  /// the user is also automatically included.
  Future<FirebaseFunctionsCallableResult> call<T>([Object? parameters]);
}

/// Firebase functions callable result.
abstract class FirebaseFunctionsCallableResult<T> {
  /// The data that was returned from the Callable HTTPS trigger.
  T get data;
}

/// Firebase functions callable result default mixin
mixin FirebaseFunctionsCallableResultDefaultMixin<T>
    implements FirebaseFunctionsCallableResult<T> {
  @override
  T get data =>
      throw UnimplementedError('FirebaseFunctionsCallableResult.data');
}

/// Firebase functions call default mixin
mixin FirebaseFunctionsCallDefaultMixin implements FirebaseFunctionsCall {
  @override
  FirebaseFunctionsCallable callable(String name,
      {FirebaseFunctionsCallableOptions? options}) {
    throw UnimplementedError('FirebaseFunctionsCall.callable');
  }
}

/// Firebase functions call service
abstract class FirebaseFunctionsCallService {
  /// Get the firebase functions call instance
  FirebaseFunctionsCall functionsCall(App app, {required String region});
}

/// Firebase functions call service default mixin
mixin FirebaseFunctionsCallServiceDefaultMixin
    implements FirebaseFunctionsCallService {
  @override
  FirebaseFunctionsCall functionsCall(App app, {required String region}) {
    throw UnimplementedError(
        'FirebaseFunctionsCallService.functionsCall(${app.name}, $region)');
  }
}

/// Firebase functions callable default mixin
mixin FirebaseFunctionsCallableDefaultMixin
    implements FirebaseFunctionsCallable {
  @override
  Future<FirebaseFunctionsCallableResult> call<T>([Object? parameters]) {
    throw UnimplementedError('FirebaseFunctionsCallable.call');
  }
}

// ignore: unused_element
class _FirebaseFunctionsCallMock
    with FirebaseFunctionsCallDefaultMixin
    implements FirebaseFunctionsCall {}

// ignore: unused_element
class _FirebaseFunctionsCallServiceMock
    with FirebaseFunctionsCallServiceDefaultMixin
    implements FirebaseFunctionsCallService {}

// ignore: unused_element
class _FirebaseFunctionsCallableMock
    with FirebaseFunctionsCallableDefaultMixin
    implements FirebaseFunctionsCallable {}

// ignore: unused_element
class _FirebaseFunctionsCallableResultsMock
    with FirebaseFunctionsCallableResultDefaultMixin
    implements FirebaseFunctionsCallableResult {}
