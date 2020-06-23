import 'package:lastfm_dashboard_domain/domain.dart';
import 'image.dart';
import '../db_mapper.dart';

class UserSetupSyncMapper extends LiteMapper<UserSetupSync> {
  UserSetupSync fromMap(Map<String, dynamic> dbMap) => UserSetupSync(
      passed: (dbMap['passed'] as int).boolean,
      earliestScrobble: dbMap['earliestScrobble'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(dbMap['earliestScrobble']));

  Map<String, dynamic> toMap(UserSetupSync s) => {
        'passed': s.passed.integer,
        'earliestScrobble': s.earliestScrobble?.millisecondsSinceEpoch
      };
  const UserSetupSyncMapper();
}

class UserMapper extends SqliteMapper<User> {
  final UserSetupSyncMapper syncMapper;
  final ImageInfoMapper imageMapper;
  UserMapper({
    this.syncMapper = const UserSetupSyncMapper(),
    this.imageMapper = const ImageInfoMapper(),
  });

  @override
  User fromMap(Map<String, dynamic> dbMap) {
    return User(
        playCount: dbMap['playCount'],
        setupSync: syncMapper.fromMap(unpackDbMap(dbMap, 'setupSync')),
        imageInfo: imageMapper.fromMap(unpackDbMap(dbMap, 'imageInfo')),
        lastSync: dbMap['lastSync'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(dbMap['lastSync']));
  }

  @override
  String key(User object) {
    return object.id;
  }

  @override
  Map<String, dynamic> toMap(User o) => {
        'lastSync': o.lastSync?.millisecondsSinceEpoch,
        'setupSync': o.setupSync.nullOr(syncMapper.toMap),
        'playCount': o.playCount,
        'imageInfo': o.imageInfo.nullOr(imageMapper.toMap),
      };
}
