import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:verifai/shared/models/user.dart';

part 'admin_identity.freezed.dart';
part 'admin_identity.g.dart';

/// Who the signed-in user is on the staff side (GET /api/auth/me).
/// `role` is null for regular learners; 'super' | 'admin' | 'moderator' for
/// staff. The profile screen shows a role badge for staff and an "Open Admin
/// Panel" button that opens the dashboard in an in-app browser view.
@freezed
class AdminIdentity with _$AdminIdentity {
  const factory AdminIdentity({
    required User user,
    @Default(false) bool isAdmin,
    String? role,
  }) = _AdminIdentity;

  factory AdminIdentity.fromJson(Map<String, dynamic> json) =>
      _$AdminIdentityFromJson(json);
}
