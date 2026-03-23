import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user.dart';

abstract class UserProvider {
  Future<void> addUser(User user);
}

class FirestoreUserProvider implements UserProvider {
  @override
  Future<void> addUser(User user) {
    final users = FirebaseFirestore.instance.collection("users");
    return users.add({
      'name': user.name,
    });
  }
}