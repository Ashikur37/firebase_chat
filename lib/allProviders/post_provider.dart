import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_social/allConstants/constants.dart';
import 'package:flutter_social/allModels/post.dart';
import 'package:flutter_social/allModels/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostProvider {
  final SharedPreferences prefs;
  final FirebaseFirestore firebaseFirestore;
  final FirebaseStorage firebaseStorage;

  PostProvider({
    required this.prefs,
    required this.firebaseFirestore,
    required this.firebaseStorage,
  });
  UploadTask uploadTask(File image, String filename) {
    Reference reference = firebaseStorage.ref().child(filename);
    UploadTask uploadTask = reference.putFile(image);
    return uploadTask;
  }

  Future<void> updateDataFirestore(String collectionPath, String docPath,
      Map<String, dynamic> dataNeedUpdate) async {
    return firebaseFirestore
        .collection(collectionPath)
        .doc(docPath)
        .update(dataNeedUpdate);
  }

  Stream<QuerySnapshot> getPostStream(int limit) {
    return firebaseFirestore
        .collection(FirestoreConstants.pathPostCollection)
        .orderBy(FirestoreConstants.timestamp, descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<User> getDataFireStore(String path) async {
    DocumentSnapshot snapshot = await firebaseFirestore
        .collection(FirestoreConstants.pathUserCollection)
        .doc(path)
        .get();
    return User.fromJson(snapshot.data() as Map<String, dynamic>);
  }

  void savePost(String content, String currentUserId, String photoUrl) {
    DocumentReference documentReference = firebaseFirestore
        .collection(FirestoreConstants.pathPostCollection)
        .doc(DateTime.now().millisecondsSinceEpoch.toString());
    Post post = Post(
      user: currentUserId,
      photoUrl: photoUrl,
      timeStamp: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
    );
    FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.set(documentReference, post.toJson());
    });
  }
}
