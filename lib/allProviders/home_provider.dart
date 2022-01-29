import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_social/allConstants/constants.dart';

class HomeProvider {
  final FirebaseFirestore firebaseFirestore;
  HomeProvider({required this.firebaseFirestore});
  Future<void> updateDataFireStore(String collectionPath, String path,
      Map<String, String> dataNeedUpdate) async {
    return firebaseFirestore
        .collection(collectionPath)
        .doc(path)
        .update(dataNeedUpdate);
  }

  Stream<QuerySnapshot> getStreamFireStore(
      String pathCollection, int limit, String? textSearch) {
    if (textSearch?.isNotEmpty == true) {
      return firebaseFirestore
          .collection(pathCollection)
          .limit(limit)
          .where(FirestoreConstants.nickname, isEqualTo: textSearch)
          .snapshots();
      // .collection(pathCollection)
// .orderBy(FirestoreConstants.nicknam
// .limit(limit)
// .startAt([textSearch]).snapshots();
    }
    return firebaseFirestore
        .collection(pathCollection)
        .limit(limit)
        .snapshots();
  }
}
