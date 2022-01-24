import 'package:flutter/material.dart';
import 'package:flutter_social/allConstants/constants.dart';
import 'package:flutter_social/allScreens/login_screen.dart';
import 'package:flutter_social/allScreens/setting_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../allModels/popup_choices.dart';
import '../allProviders/auth_provider.dart';
import '../main.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GoogleSignIn googleSignin = GoogleSignIn();
  final ScrollController listScrollController = ScrollController();

  int _limit = 20;
  int _limitIncrement = 20;
  String textSearch = "";
  bool isLoading = false;
  late String currentUserId;
  late AuthProvider authProvider;
  // late HomeProvider homeProvider;

  Future<void> handleSignOut() async {
    authProvider.handleSignOut();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void onItemMenuPressed(PopupChoices choice) {
    if (choice.title == "Sign Out") {
      handleSignOut();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SettingPage(),
        ),
      );
    }
  }

  void scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  List<PopupChoices> choices = [
    PopupChoices(title: "Settings", icon: Icons.settings),
    PopupChoices(title: "Sign Out", icon: Icons.exit_to_app),
  ];
  @override
  initState() {
    super.initState();
    authProvider = context.read<AuthProvider>();
    // homeProvider=context.read<HomeProvider>();
    if (authProvider.getFirebaseUserId()?.isNotEmpty == true) {
      currentUserId = authProvider.getFirebaseUserId()!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
          (Route<dynamic> route) => false);
    }
    listScrollController.addListener(scrollListener);
  }

  Widget buildPopupMenu() {
    return PopupMenuButton<PopupChoices>(
        icon: const Icon(
          Icons.more_vert,
          color: Colors.grey,
        ),
        onSelected: onItemMenuPressed,
        itemBuilder: (BuildContext context) {
          return choices.map((PopupChoices choice) {
            return PopupMenuItem<PopupChoices>(
              value: choice,
              child: Row(
                children: [
                  Icon(
                    choice.icon,
                    color: ColorConstants.primaryColor,
                  ),
                  Container(
                    width: 10,
                  ),
                  Text(
                    choice.title,
                    style: const TextStyle(
                      color: ColorConstants.primaryColor,
                    ),
                  )
                ],
              ),
            );
          }).toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isWhite ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: isWhite ? Colors.white : Colors.black,
        leading: IconButton(
          icon: Switch(
            value: isWhite,
            onChanged: (val) {
              setState(() {
                isWhite = val;
              });
            },
            activeTrackColor: Colors.grey,
            activeColor: Colors.white,
            inactiveTrackColor: Colors.grey,
            inactiveThumbColor: Colors.black45,
          ),
          onPressed: () {},
        ),
        actions: [
          buildPopupMenu(),
        ],
      ),
    );
  }
}
