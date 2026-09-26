import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

FirebaseDatabase getDatabase() {
  return FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://campus-move00-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
}