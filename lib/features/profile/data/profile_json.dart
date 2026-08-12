import 'profile_service.dart';

/// JSON adapter for [UserProfile]. Kept separate from
/// [ProfileService] because the service is a `ChangeNotifier` and we
/// don't want to mix presentation concerns with serialization.
///
/// Wire shape for the cloud profile doc (`users/{uid}/profile/profile`):
///   - `username`    : String, the user's public login name.
///   - `displayName` : String, the user's chosen display name.
///   - `email`       : String, contact email.
///   - `createdAt`   : int millisecondsSinceEpoch, when this profile
///                     was first created on the *cloud* side. May be
///                     absent on a freshly-restored row.
///   - `updatedAt`   : int millisecondsSinceEpoch, last mutation.
///
/// Avatars are deliberately *not* synced — `avatarPath` is a device-
/// local file path and stays on the device that picked it.
class ProfileJson {
  const ProfileJson._();

  static Map<String, dynamic> toMap(UserProfile profile, {DateTime? now}) {
    final ts = (now ?? DateTime.now()).millisecondsSinceEpoch;
    return {
      'displayName': profile.name,
      'email': profile.email,
      'updatedAt': ts,
    };
  }

  static UserProfile fromMap(Map<String, dynamic> json) {
    return UserProfile(
      name:
          (json['displayName'] as String?) ??
          (json['name'] as String?) ??
          UserProfile.empty.name,
      email: (json['email'] as String?) ?? UserProfile.empty.email,
    );
  }
}
