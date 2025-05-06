import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:final_4330/Databaseservice.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockUser extends Mock implements User {}

void main() {
  group('DatabaseService', () {
    late MockFirebaseAuth mockAuth;
    late MockDatabaseReference mockDb;
    late DatabaseService service;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockDb = MockDatabaseReference();
      service = DatabaseService(); // You'd modify to inject mocks
    });

    test('getCurrentUserId returns guest when user is null', () {
      // Simulate _auth.currentUser being null
      when(mockAuth.currentUser).thenReturn(null);
      final id = service.getCurrentUserId();
      expect(id.startsWith("guest_"), true);
    });
  });
}