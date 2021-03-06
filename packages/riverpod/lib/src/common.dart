import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:meta/meta.dart';

import 'framework/framework.dart';
import 'future_provider/future_provider.dart';
import 'provider/provider.dart';
import 'stream_provider/stream_provider.dart';

part 'common.freezed.dart';

/// A callback used by providers to create the value exposed.
///
/// If an exception is thrown within that callback, all attempts at reading
/// the provider associated with the given callback will throw.
///
/// The parameter [ref] can be used to interact with other providers
/// and the life-cycles of this provider.
///
/// See also:
///
/// - [ProviderReference], which exposes the methods to read other providers.
/// - [Provider], a provier that uses [Create] to expose an immutable value.
typedef Create<Result, Ref extends ProviderReference> = Result Function(
  Ref ref,
);

typedef VoidCallback = void Function();

/// An utility for safely manipulating asynchronous data.
///
/// By using [AsyncValue], you are guanranteed that you cannot forget to
/// handle the loading/error state of an asynchrounous operation.
///
/// It also expose some utilities to nicely convert an [AsyncValue] to
/// a different object.
/// For example, a Flutter Widget may use [when] to convert an [AsyncValue]
/// into either a progress indicator, an error screen, or to show the data:
///
/// ```dart
/// /// A provider that asynchronously expose the current user
/// final userProvider = StreamProvider<User>((_) async* {
///   // fetch the user
/// });
///
/// class Example extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final AsyncValue<User> user = useProvider(userProvider);
///
///     return user.when(
///       loading: () => CircularProgressIndicator(),
///       error: (error, stack) => Text('Oops, something unexpected happened'),
///       data: (value) => Text('Hello ${user.name}'),
///     );
///   }
/// }
/// ```
///
/// If a consumer of an [AsyncValue] does not care about the loading/error
/// state, consider using [data] to read the state.
///
/// See also:
///
/// - [FutureProvider] and [StreamProvider], which transforms a [Future] into
///   an [AsyncValue].
/// - The package Freezed (https://github.com/rrousselgit/freezed), which have
///   generated this [AsyncValue] class and explains how [map]/[when] works.
@freezed
abstract class AsyncValue<T> with _$AsyncValue<T> {
  const AsyncValue._();

  /// Creates an [AsyncValue] with a data.
  ///
  /// The data can be `null`.
  const factory AsyncValue.data(@nullable T value) = AsyncData<T>;

  /// Creates an [AsyncValue] in loading state.
  ///
  /// Prefer always using this constructor with the `const` keyword.
  const factory AsyncValue.loading() = AsyncLoading<T>;

  /// Creates an [AsyncValue] in error state.
  ///
  /// The parameter [error] cannot be `null`.
  factory AsyncValue.error(Object error, [StackTrace stackTrace]) =
      AsyncError<T>;

  /// The current data, or null if in loading/error.
  ///
  /// This is safe to use, as Dart (will) have non-nullable types.
  /// As such reading [data] still forces to handle the loading/error cases
  /// by having to check `data != null`.
  ///
  /// ## Why does [AsyncValue<T>.data] return [AsyncData<T>] instead of [T]?
  ///
  /// The motivation behind this decision is to allow differenciating between:
  ///
  /// - There is a data, and it is `null`.
  ///   ```dart
  ///   // There is a data, and it is "null"
  ///   AsyncValue<Configuration> configs = AsyncValue.data(null);
  ///
  ///   print(configs.data); // AsyncValue(value: null)
  ///   print(configs.data.value); // null
  ///   ```
  ///
  /// - There is no data. [AsyncValue] is currently in loading/error state.
  ///   ```dart
  ///   // No data, currently loading
  ///   AsyncValue<Configuration> configs = AsyncValue.loading();
  ///
  ///   print(configs.data); // null, currently loading
  ///   print(configs.data.value); // throws null exception
  ///   ```
  AsyncData<T> get data {
    return map(
      data: (data) => data,
      loading: (_) => null,
      error: (_) => null,
    );
  }
  // TODO: Add a `value` extension on non-nullable AsyncValue

  /// Shorthand for [when] to handle only the `data` case.
  AsyncValue<R> whenData<R>(R Function(T value) cb) {
    return when(
      data: (value) {
        try {
          return AsyncValue.data(cb(value));
        } catch (err, stack) {
          return AsyncValue.error(err, stack);
        }
      },
      loading: () => const AsyncValue.loading(),
      error: (err, stack) => AsyncValue.error(err, stack),
    );
  }
}
