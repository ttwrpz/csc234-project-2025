import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String? id;
  final String name;

  User._({required this.name, this.id});

  factory User.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return User._(id: snapshot.id, name: data['name']);
  }
}
