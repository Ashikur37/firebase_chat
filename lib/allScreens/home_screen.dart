import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_social/allModels/post.dart';
import 'package:flutter_social/allModels/user.dart';
import 'package:flutter_social/allProviders/post_provider.dart';
import 'package:flutter_social/allScreens/setting_page.dart';
import 'package:flutter_social/allScreens/user_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../allConstants/color_constants.dart';
import '../allModels/popup_choices.dart';
import '../allProviders/auth_provider.dart';
import '../main.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late AuthProvider authProvider;
  late PostProvider postProvider;
  TextEditingController bodyController = TextEditingController();
  int _limit = 20;
  int _limitIncrement = 20;
  List<QueryDocumentSnapshot> listPosts = List.from([]);
  final ScrollController listScrollController = ScrollController();

  String body = "";
  late String currentUserId;
  Future<void> handleSignOut() async {
    authProvider.handleSignOut();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    bodyController.dispose();
    listScrollController.dispose();
  }

  @override
  initState() {
    super.initState();
    authProvider = context.read<AuthProvider>();
    postProvider = context.read<PostProvider>();

    if (authProvider.getFirebaseUserId()?.isNotEmpty == true) {
      currentUserId = authProvider.getFirebaseUserId()!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
          (Route<dynamic> route) => false);
    }
    listScrollController.addListener(_scrollListener);
  }

  _scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  Future<void> uploadPost() async {
    if (body.isNotEmpty) {
      postProvider.savePost(body, currentUserId, "");
      bodyController.clear();
    }
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

  List<PopupChoices> choices = [
    PopupChoices(title: "Settings", icon: Icons.settings),
    PopupChoices(title: "Sign Out", icon: Icons.exit_to_app),
  ];
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
        title: TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UserListScreen(),
              ),
            );
          },
          child: Text(
            "User List",
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          buildPopupMenu(),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: bodyController,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: 'whats on your mind',
                hintText: 'Share your thinking',
              ),
              onChanged: (val) {
                body = val;
              },
            ),
          ),
          TextButton(onPressed: uploadPost, child: Text('upload')),
          buildListPost()
        ],
      ),
    );
  }

  Widget buildListPost() {
    return Flexible(
      child: StreamBuilder(
          stream: postProvider.getPostStream(_limit),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasData) {
              listPosts.addAll(snapshot.data!.docs);
              return ListView.builder(
                padding: const EdgeInsets.all(10.0),
                itemBuilder: (context, index) =>
                    buildItem(index, snapshot.data!.docs[index]),
                itemCount: snapshot.data!.docs.length,
                reverse: true,
                controller: listScrollController,
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          }),
    );
  }

  Widget buildItem(int index, DocumentSnapshot? document) {
    if (document != null) {
      Post post = Post.fromDocument(document);
      return Container(
        child: Column(
          children: [
            ListTile(
              title: Text(post.content),
              subtitle: nameBuilder(post.user),
            ),
            Divider(),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  Widget nameBuilder(String user) {
    return FutureBuilder<User>(
        builder: ((context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Text(snapshot.data!.nickName);
          } else {
            return Shimmer.fromColors(
              baseColor: Color(0xFF00AFB4).withOpacity(.9),
              highlightColor: Colors.amber,
              child: Text(
                'User',
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
        }),
        future: postProvider.getDataFireStore(user));
  }
}
