import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<void> writeCardPutDown(String card, String user, String gameID) async {
    _db.child("Deck/$gameID");
  }
}
