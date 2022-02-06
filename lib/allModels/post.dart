import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_social/allConstants/firestore_constants.dart';

class Post {
  String timeStamp;
  String content;
  String photoUrl;
  String user;

  Post(
      {required this.timeStamp,
      required this.content,
      required this.user,
      this.photoUrl = ""});

  Map<String, dynamic> toJson() {
    return {
      FirestoreConstants.timestamp: timeStamp,
      FirestoreConstants.content: content,
      FirestoreConstants.photoUrl: photoUrl,
      FirestoreConstants.user: user,
    };
  }

  factory Post.fromDocument(DocumentSnapshot doc) {
    String photoUrl = doc.get(FirestoreConstants.photoUrl);
    String timeStamp = doc.get(FirestoreConstants.timestamp);
    String content = doc.get(FirestoreConstants.content);
    String user = doc.get(FirestoreConstants.user);
    return Post(
        timeStamp: timeStamp, content: content, user: user, photoUrl: photoUrl);
  }
}
