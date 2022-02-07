import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_social/allModels/post.dart';
import 'package:flutter_social/allModels/user.dart';
import 'package:flutter_social/allProviders/post_provider.dart';
import 'package:flutter_social/allScreens/setting_page.dart';
import 'package:flutter_social/allScreens/user_list_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
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
  File? imageFile;
  String imageUrl = "";
  String body = "";
  bool isLoading = false;
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

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? pickedFile = await imagePicker
        .pickImage(source: ImageSource.camera)
        .catchError((err) {
      Fluttertoast.showToast(msg: err.toString());
    });
    File? image;
    if (pickedFile != null) {
      image = File(pickedFile.path);
    }
    if (image != null) {
      setState(() {
        imageFile = image;
      });
    }
  }

  Future uploadFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    UploadTask uploadTask = postProvider.uploadTask(imageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      var url = await snapshot.ref.getDownloadURL();
      setState(() {
        isLoading = false;
        imageUrl = url;
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  Future<bool> onBackPress() async {
    openDialog();
    return Future.value(false);
  }

  Future<void> openDialog() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            clipBehavior: Clip.hardEdge,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.zero,
            children: [
              Container(
                color: ColorConstants.themeColor,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      child: const Icon(
                        Icons.exit_to_app,
                        size: 30,
                        color: Colors.white,
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                    ),
                    const Text(
                      "Exit App",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "Are You Sure to Exit App",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 0);
                },
                child: Row(
                  children: [
                    Container(
                      child: const Icon(
                        Icons.cancel,
                        color: ColorConstants.primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10),
                    ),
                    const Text(
                      "Cancel",
                      style: TextStyle(
                          color: ColorConstants.primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                child: Row(
                  children: [
                    Container(
                      child: const Icon(
                        Icons.check_circle,
                        color: ColorConstants.primaryColor,
                      ),
                      margin: const EdgeInsets.only(right: 10),
                    ),
                    const Text(
                      "Yes",
                      style: TextStyle(
                          color: ColorConstants.primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            ],
          );
        })) {
      case 0:
        break;
      case 1:
        exit(0);
    }
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
    if (listScrollController.position.pixels ==
        listScrollController.position.maxScrollExtent) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  Future<void> uploadPost() async {
    if (imageFile != null) {
      setState(() {
        isLoading = true;
      });
      await uploadFile();
      setState(() {
        imageFile = null;
      });
    }
    if (body.isNotEmpty) {
      postProvider.savePost(body, currentUserId, imageUrl);
      bodyController.clear();
      setState(() {
        imageUrl = "";
      });
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
      body: WillPopScope(
        onWillPop: onBackPress,
        child: Column(
          children: [buildListPost()],
        ),
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
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
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
                        Material(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.0),
                            child: IconButton(
                              icon: const Icon(Icons.image),
                              onPressed: getImage,
                              color: Colors.blue,
                            ),
                          ),
                          color: Colors.white,
                        ),
                        TextButton(
                            onPressed: uploadPost, child: const Text('Share'))
                      ],
                    );
                  } else {
                    return buildItem(index - 1, snapshot.data!.docs[index - 1]);
                  }
                },
                itemCount: snapshot.data!.docs.length + 1,
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
            post.photoUrl == ""
                ? SizedBox.shrink()
                : Container(
                    child: Image.network(
                      post.photoUrl,
                      fit: BoxFit.cover,
                    ),
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
