import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_social/allConstants/constants.dart';
import 'package:flutter_social/allModels/user_chat.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Status {
  uninitialized,
  athenticated,
  authenticating,
  authenticateError,
  authenticateCanceled,
}

class AuthProvider extends ChangeNotifier {
  Status _status = Status.uninitialized;
  final GoogleSignIn googleSignIn;
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firebaseFirestore;
  final SharedPreferences pref;

  Status get status => _status;

  AuthProvider(
      {required this.googleSignIn,
      required this.firebaseAuth,
      required this.firebaseFirestore,
      required this.pref});
  String? getFirebaseUserId() {
    return pref.getString(FirestoreConstants.id);
  }

  setFirebaseUserId(String id) {
    pref.setString(FirestoreConstants.id, id);
  }

  Future<bool> isLoggedIn() async {
    bool loggedIn = await googleSignIn.isSignedIn();
    return loggedIn &&
        pref.getString(FirestoreConstants.id)?.isNotEmpty == true;
  }

  Future<bool> handleSignIn() async {
    _status = Status.authenticating;
    notifyListeners();
    GoogleSignInAccount? user = await googleSignIn.signIn();
    if (user != null) {
      GoogleSignInAuthentication googleAuth = await user.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      User? firebaseUser =
          (await firebaseAuth.signInWithCredential(credential)).user;
      if (firebaseUser != null) {
        final QuerySnapshot result = await firebaseFirestore
            .collection(FirestoreConstants.pathUserCollection)
            .where(FirestoreConstants.id, isEqualTo: firebaseUser.uid)
            .get();
        final List<DocumentSnapshot> doc = result.docs;
        if (doc.isEmpty) {
          firebaseFirestore
              .collection(FirestoreConstants.pathUserCollection)
              .doc(firebaseUser.uid)
              .set({
            FirestoreConstants.nickname: firebaseUser.displayName,
            FirestoreConstants.photoUrl: firebaseUser.photoURL,
            FirestoreConstants.id: firebaseUser.uid,
            'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
            FirestoreConstants.chattingWith: null
          });
          User? currentUser = firebaseUser;
          await pref.setString(FirestoreConstants.id, currentUser.uid);
          await pref.setString(
              FirestoreConstants.nickname, currentUser.displayName ?? "");
          await pref.setString(
              FirestoreConstants.photoUrl, currentUser.photoURL ?? "");
          await pref.setString(
              FirestoreConstants.phoneNumber, currentUser.phoneNumber ?? "");
        } else {
          DocumentSnapshot documentSnapshot = doc[0];
          UserChat userChat = UserChat.fromDocument(documentSnapshot);
          await pref.setString(FirestoreConstants.id, userChat.id);
          await pref.setString(FirestoreConstants.nickname, userChat.nickName);
          await pref.setString(FirestoreConstants.photoUrl, userChat.photoUrl);
          await pref.setString(FirestoreConstants.aboutMe, userChat.aboutMe);
          await pref.setString(
              FirestoreConstants.phoneNumber, userChat.phoneNumber);
        }
        _status = Status.athenticated;
        notifyListeners();
        return true;
      } else {
        _status = Status.authenticateError;
        notifyListeners();
        return false;
      }
    } else {
      _status = Status.authenticateCanceled;
      notifyListeners();
      return false;
    }
  }

  Future<void> handleSignOut() async {
    _status = Status.uninitialized;
    notifyListeners();
    await firebaseAuth.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();
  }
}
