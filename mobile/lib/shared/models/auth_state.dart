import 'package:freezed_annotation/freezed_annotation.dart';
import 'user.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.authenticated({
    required User user,
    required String token,
  }) = _Authenticated;
  const factory AuthState.needsOnboarding({
    required User user,
    required String token,
  }) = _NeedsOnboarding;
  const factory AuthState.loading() = _Loading;
}