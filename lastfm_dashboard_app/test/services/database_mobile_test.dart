import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:collection/collection.dart';

import 'package:lastfm_dashboard/services/local_database/mobile/database_service.dart';
import 'package:lastfm_dashboard/models/models.dart';

void main() {
  group('Mobile Database', () {
    sqfliteFfiInit();
    MobileDatabaseService db;
    test('Database creation', () async {
      final builder = MobileDatabaseBuilder(
        path: inMemoryDatabasePath,
        dbFactory: databaseFactoryFfi,
        absolutePath: true,
      );
      db = await builder.build();
      await db.database.getVersion();
    });

    group('UsersCollection tests', () {
      User getUser(int seed) {
        return User(
          username: 'testUser$seed',
          imageInfo: ImageInfo(
            extraLarge: 'https://image/extraLarge/$seed',
            large: 'https://image/large/$seed',
            medium: 'https://image/medium/$seed',
            small: 'https://image/small/$seed',
          ),
          lastSync: DateTime.now().add(Duration(hours: seed)),
          playCount: 1000 * seed,
          setupSync: UserSetupSync(
            latestScrobble: DateTime(2015 + seed),
            passed: true,
          ),
        );
      }

      final testUser = getUser(0);
      test('add, get, exists and remove', () async {
        final stream = db.users[testUser.id].changes();
        expect(
            stream,
            emitsInOrder([
              (Event e) =>
                  e.changes.length == 1 &&
                  !e.changes[0].deleted &&
                  e.changes[0].id == testUser.id &&
                  e.changes[0].updated.length ==
                      testUser.toDbMapFlat().length &&
                  e.itemsId[0] == testUser.id &&
                  e.tableName == db.users.tableName,
              (Event e) =>
                  e.changes.length == 1 &&
                  e.changes[0].deleted &&
                  e.itemsId[0] == testUser.id &&
                  e.changes[0].updated.isEmpty &&
                  e.tableName == db.users.tableName
            ]));

        final notExist = await db.users[testUser.id].exists();
        expect(notExist, false);

        final nullUser = await db.users[testUser.id].get();
        expect(nullUser, null);

        await db.users.add(testUser);
        final retUser = await db.users[testUser.id].get();
        expect(retUser.diff(testUser).length, 0);

        final exist = await db.users[testUser.id].exists();
        expect(exist, true);

        await db.users[testUser.id].delete();
        final removedUser = await db.users[testUser.id].get();
        expect(removedUser, null);
      });
      test('update selective', () async {
        final stream = db.users[testUser.id].changes();
        expect(
            stream,
            emitsInOrder([
              (Event e) =>
                  e.changes.length == 1 &&
                  !e.changes[0].deleted &&
                  e.itemsId.length == 1 &&
                  e.itemsId[0] == testUser.id &&
                  e.tableName == db.users.tableName,
              (Event e) =>
                  e.changes.length == 1 &&
                  !e.changes[0].deleted &&
                  e.itemsId.length == 1 &&
                  e.itemsId[0] == testUser.id &&
                  e.tableName == db.users.tableName,
              (Event e) =>
                  e.changes.length == 1 &&
                  !e.changes[0].deleted &&
                  e.itemsId[0] == testUser.id &&
                  e.tableName == db.users.tableName,
              (Event e) =>
                  e.changes.length == 1 &&
                  e.changes[0].deleted &&
                  e.itemsId.length == 1 &&
                  e.itemsId[0] == testUser.id &&
                  e.tableName == db.users.tableName
            ]));

        final newUser = getUser(1);

        final nullUser = await db.users[testUser.id].get();
        expect(nullUser, null);

        try {
          // modifying user that doesnt exists with createIfNotExist = false
          await db.users[testUser.id]
              .updateSelective((u) => testUser, createIfNotExist: false);
          throw Exception('Throw expected');
        } catch (e) {
          expect(e, isInstanceOf<SqliteDatabaseException>());
        }
        // user creation through updateSelective with createIfNotExists = true
        await db.users[testUser.id].updateSelective((u) => testUser);

        // modifying user through updateSelective
        await db.users[testUser.id]
            .updateSelective((u) => u.copyWith(username: 'temp'));
        final updatedUser = await db.users[testUser.id].get();
        expect(updatedUser.diffFlat(testUser).length, 1);

        // replacing user through updateSelective
        await db.users[testUser.id].updateSelective((u) => newUser);
        final retUser = await db.users[testUser.id].get();
        expect(retUser.diffFlat(testUser).length, 7);

        await db.users[testUser.id].delete();
        final removedUser = await db.users[testUser.id].get();
        expect(removedUser, null);
      });
      test('add all', () async {
        final users = [
          getUser(0),
          getUser(1),
          getUser(2),
          getUser(3),
        ];

        final stream = db.users[testUser.id].changes();
        expect(
            stream,
            emitsInOrder([
              (Event e) =>
                  e.changes.length == users.length &&
                  e.changes.asMap().entries.every((entry) =>
                      entry.value.id == users[entry.key].id &&
                      entry.value.updated.length ==
                          users[entry.key].toDbMapFlat().length) &&
                  const ListEquality()
                      .equals(e.itemsId, users.map((e) => e.id).toList()) &&
                  e.tableName == db.users.tableName,
              for (final u in users)
                (Event e) =>
                    e.changes.length == 1 &&
                    e.changes[0].deleted &&
                    e.itemsId.length == 1 &&
                    e.itemsId[0] == u.id &&
                    e.tableName == db.users.tableName
            ]));

        final nullUser = await db.users[testUser.id].get();
        expect(nullUser, null);
        await db.users.addAll(users);

        for (final u in users) {
          final dbUser = await db.users[u.id].get();
          expect(dbUser.diff(u).length, 0);

          await db.users[u.id].delete();
          final deletedUser = await db.users[u.id].get();
          expect(deletedUser, null);
        }
      });
    });
  });
}
