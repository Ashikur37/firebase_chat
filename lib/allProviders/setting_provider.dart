import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingProvider {
  final FirebaseFirestore firebaseFirestore;
  final SharedPreferences pref;
  final FirebaseStorage firebaseStorage;

  SettingProvider({
    required this.firebaseFirestore,
    required this.pref,
    required this.firebaseStorage,
  });

  String? getPref(String key) {
    return pref.getString(key);
  }

  Future<bool> setPref(String key, String value) async {
    return await pref.setString(key, value);
  }

  UploadTask uploadFile(File image, String fileName) {
    Reference reference = firebaseStorage.ref().child(fileName);
    UploadTask uploadTask = reference.putFile(image);
    return uploadTask;
  }

  Future<void> updateDataFireStore(String collectionPath, String path,
      Map<String, String> dataNeedUpdate) async {
    return firebaseFirestore
        .collection(collectionPath)
        .doc(path)
        .update(dataNeedUpdate);
  }
}
