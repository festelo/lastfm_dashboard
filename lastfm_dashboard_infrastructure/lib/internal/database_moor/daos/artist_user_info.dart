import 'dart:async';

import 'package:lastfm_dashboard_domain/domain.dart';
import 'package:moor/moor.dart';

import '../database.dart';
import '../mappers.dart';

class ArtistUserInfoDataAccessor extends DatabaseAccessor<MoorDatabase> {
  ArtistUserInfoDataAccessor(MoorDatabase attachedDatabase,
      {this.mapper = const ArtistUserInfoMapper()})
      : super(attachedDatabase);
  final ArtistUserInfoMapper mapper;
  static const maxRowsNumber = 1000000;

  Future<List<ArtistUserInfo>> getWhere({
    List<String> userIds,
    List<String> artistIds,
    int skip,
    int take,
    SortDirection scrobblesSort,
  }) async {
    final userEx = userIds == null
        ? Constant(true)
        : db.trackScrobbles.userId.isIn(userIds);
    final artistEx = artistIds == null
        ? Constant(true)
        : db.trackScrobbles.artistId.isIn(artistIds);
    final where = userEx & artistEx;
    final term = scrobblesSort == SortDirection.ascending
        ? OrderingTerm.asc(CustomExpression('scrobbles'))
        : OrderingTerm.desc(CustomExpression('scrobbles'));
    final res = await this
        .db
        .artists_by_user_detailed(where, OrderBy([term]),
            Constant(take ?? maxRowsNumber), Constant(skip ?? 0))
        .get();
    return res.map(mapper.toDomain).toList();
  }
}

// @override
// Future<T> transaction<T>(FutureOr<T> Function() action) {
//   return transaction(() async => await action());
// }
