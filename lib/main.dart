import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_social/allConstants/app_constants.dart';
import 'package:flutter_social/allProviders/auth_provider.dart';
import 'package:flutter_social/allProviders/chat_provider.dart';
import 'package:flutter_social/allProviders/home_provider.dart';
import 'package:flutter_social/allProviders/post_provider.dart';
import 'package:flutter_social/allProviders/setting_provider.dart';
import 'package:flutter_social/allScreens/splash_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool isWhite = false;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(MyApp(
    prefs: prefs,
  ));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final FirebaseStorage firebaseStorage = FirebaseStorage.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  MyApp({Key? key, required this.prefs}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
              googleSignIn: GoogleSignIn(),
              firebaseAuth: FirebaseAuth.instance,
              firebaseFirestore: firebaseFirestore,
              pref: prefs),
        ),
        Provider<SettingProvider>(
          create: (_) => SettingProvider(
            firebaseStorage: firebaseStorage,
            firebaseFirestore: firebaseFirestore,
            pref: prefs,
          ),
        ),
        Provider<HomeProvider>(
          create: (_) => HomeProvider(
            firebaseFirestore: firebaseFirestore,
          ),
        ),
        Provider<ChatProvider>(
          create: (_) => ChatProvider(
              prefs: prefs,
              firebaseFirestore: firebaseFirestore,
              firebaseStorage: firebaseStorage),
        ),
        Provider<PostProvider>(
          create: (_) => PostProvider(
              prefs: prefs,
              firebaseFirestore: firebaseFirestore,
              firebaseStorage: firebaseStorage),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appTitle,
        theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.blue,
        ),
        home: const SplashPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
//  SHA1: 8E:04:47:8B:EA:A1:BC:52:E5:1E:85:11:6E:84:27:F3:B4:B1:AF:79
	//  SHA256: EC:CA:CA:91:D0:FC:4C:CC:F9:CD:C9:14:58:56:3C:7C:D4:44:2D:BF:09:53:83:61:90:CD:DC:F3:D5:99:A1:8C