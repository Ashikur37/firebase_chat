import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_social/allConstants/firestore_constants.dart';

class UserChat {
  String id;
  String photoUrl;
  String nickName;
  String aboutMe;
  String phoneNumber;
  UserChat({
    required this.id,
    required this.photoUrl,
    required this.nickName,
    required this.aboutMe,
    required this.phoneNumber,
  });
  Map<String, String> toJson() {
    return {
      FirestoreConstants.photoUrl: photoUrl,
      FirestoreConstants.nickname: nickName,
      FirestoreConstants.aboutMe: aboutMe,
      FirestoreConstants.phoneNumber: phoneNumber,
    };
  }

  factory UserChat.fromDocument(DocumentSnapshot doc) {
    String aboutMe = "";
    String photoUrl = "";
    String nickName = "";

    String phoneNumber = "";
    try {
      aboutMe = doc.get(FirestoreConstants.aboutMe);
    } catch (e) {}
    try {
      phoneNumber = doc.get(FirestoreConstants.phoneNumber);
    } catch (e) {}
    try {
      photoUrl = doc.get(FirestoreConstants.photoUrl);
    } catch (e) {}
    try {
      nickName = doc.get(FirestoreConstants.nickname);
    } catch (e) {}
    return UserChat(
        id: doc.id,
        photoUrl: photoUrl,
        nickName: nickName,
        aboutMe: aboutMe,
        phoneNumber: phoneNumber);
  }
}
