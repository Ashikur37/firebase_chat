import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_social/allConstants/firestore_constants.dart';

class MessageChat {
  String idFrom;
  String idTo;
  String timeStamp;
  String content;
  int type;

  MessageChat({
    required this.idFrom,
    required this.idTo,
    required this.timeStamp,
    required this.content,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      FirestoreConstants.idFrom: idFrom,
      FirestoreConstants.idTo: idTo,
      FirestoreConstants.timestamp: timeStamp,
      FirestoreConstants.content: content,
      FirestoreConstants.type: type,
    };
  }

  factory MessageChat.fromDocument(DocumentSnapshot doc) {
    String idFrom = doc.get(FirestoreConstants.idFrom);
    String idTo = doc.get(FirestoreConstants.idTo);
    String timeStamp = doc.get(FirestoreConstants.timestamp);
    String content = doc.get(FirestoreConstants.content);
    int type = doc.get(FirestoreConstants.type);
    return MessageChat(
      idFrom: idFrom,
      idTo: idTo,
      timeStamp: timeStamp,
      content: content,
      type: type,
    );
  }
}
