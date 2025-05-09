// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/mockito.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:final_4330/Databaseservice.dart';

// class MockDatabaseReference extends Mock implements DatabaseReference {}
// class MockFirebaseAuth extends Mock implements FirebaseAuth {}
// class MockUser extends Mock implements User {}

// void main() {
//   group('DatabaseService - createNewGame', () {
//     late MockDatabaseReference mockDb;
//     late MockDatabaseReference mockDeckRef;
//     late MockDatabaseReference mockGameRef;
//     late MockFirebaseAuth mockAuth;
//     late MockUser mockUser;

//     late DatabaseService service;

//     setUp(() {
//       mockDb = MockDatabaseReference();
//       mockDeckRef = MockDatabaseReference();
//       mockGameRef = MockDatabaseReference();
//       mockAuth = MockFirebaseAuth();
//       mockUser = MockUser();

//       when(mockDb.child('deck/gameSessions')).thenReturn(mockDeckRef);
//       when(mockDeckRef.push()).thenReturn(mockGameRef);
//       when(mockGameRef.key).thenReturn('testGameId');
//       when(mockAuth.currentUser).thenReturn(mockUser);
//       when(mockUser.uid).thenReturn('testUid');

//       service = DatabaseService(auth: mockAuth, db: mockDb);
//     });

//     test('createNewGame returns the generated gameId and sets data', () async {
//       when(mockGameRef.set(any)).thenAnswer((_) async {});

//       final gameId = await service.createNewGame();

//       expect(gameId, equals('testGameId'));
//       verify(mockGameRef.set(argThat(
//         containsPair('createdBy', 'testUid'),
//       ))).called(1);
//     });
//   });
// }
