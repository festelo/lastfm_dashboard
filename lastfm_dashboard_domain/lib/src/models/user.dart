import 'package:lastfm_dashboard_domain/domain.dart';
import 'package:lastfm_dashboard_domain/src/models/entity.dart';

class UserSetupSync {
  final bool passed;
  final DateTime earliestScrobble;

  const UserSetupSync({this.passed = false, this.earliestScrobble});
}

class User extends Entity {
  final String username;
  final DateTime lastSync;
  final int playCount;
  final ImageInfo imageInfo;

  final UserSetupSync setupSync;

  User({
    String id,
    this.username,
    DateTime lastSync,
    this.playCount,
    this.imageInfo,
    this.setupSync = const UserSetupSync(),
  })  : lastSync = lastSync ?? DateTime.fromMillisecondsSinceEpoch(0),
        super(id);

  User copyWith({
    String id,
    ImageInfo imageInfo,
    DateTime lastSync,
    int playCount,
    UserSetupSync setupSync,
    String username,
  }) {
    return User(
      id: id ?? this.id,
      imageInfo: imageInfo ?? this.imageInfo,
      lastSync: lastSync ?? this.lastSync,
      playCount: playCount ?? this.playCount,
      setupSync: setupSync ?? this.setupSync,
      username: username ?? this.username,
    );
  }
}
