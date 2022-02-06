import 'package:cloud_firestore/cloud_firestore.dart';

import '../allConstants/firestore_constants.dart';

class User {
  final String nickName;

  User({required this.nickName});

  User.fromJson(Map<String, dynamic> json) : nickName = json['nickname'];

  factory User.fromDocument(DocumentSnapshot doc) {
    String nickName = doc.get(FirestoreConstants.nickname);

    return User(
      nickName: nickName,
    );
  }
}
