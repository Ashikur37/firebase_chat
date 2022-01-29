import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_social/allConstants/app_constants.dart';
import 'package:flutter_social/allConstants/constants.dart';
import 'package:flutter_social/allModels/user_chat.dart';
import 'package:flutter_social/allProviders/setting_provider.dart';
import 'package:flutter_social/allWidgets/widgets.dart';
import 'package:flutter_social/main.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isWhite ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: isWhite ? Colors.white : Colors.black,
        iconTheme: const IconThemeData(
          color: ColorConstants.primaryColor,
        ),
        title: const Text(
          AppConstants.settingsTitle,
          style: TextStyle(
            color: ColorConstants.primaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: const SettingState(),
    );
  }
}

class SettingState extends StatefulWidget {
  const SettingState({Key? key}) : super(key: key);

  @override
  _SettingStateState createState() => _SettingStateState();
}

class _SettingStateState extends State<SettingState> {
  TextEditingController? nickNameController;
  TextEditingController? aboutMeController;

  String dialCode = "+880";
  TextEditingController controller = TextEditingController();
  String id = "";
  String nickname = "";
  String aboutMe = "";
  String photoUrl = "";
  String phoneNumber = "";

  bool isLoading = false;
  File? avatarImageFile;
  late SettingProvider settingProvider;

  final FocusNode focusNodeNickName = FocusNode();
  final FocusNode focusNodeAboutMe = FocusNode();

  @override
  void initState() {
    super.initState();
    settingProvider = context.read<SettingProvider>();
    readLocal();
  }

  void readLocal() {
    setState(() {
      id = settingProvider.getPref(FirestoreConstants.id) ?? "";
      nickname = settingProvider.getPref(FirestoreConstants.nickname) ?? "";
      aboutMe = settingProvider.getPref(FirestoreConstants.aboutMe) ?? "";
      photoUrl = settingProvider.getPref(FirestoreConstants.photoUrl) ?? "";
      phoneNumber =
          settingProvider.getPref(FirestoreConstants.phoneNumber) ?? "";
    });
    nickNameController = TextEditingController(text: nickname);
    aboutMeController = TextEditingController(text: aboutMe);
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
        avatarImageFile = image;
        isLoading = true;
      });
      uploadFile();
    }
  }

  Future uploadFile() async {
    String fileName = id;
    UploadTask uploadTask =
        settingProvider.uploadFile(avatarImageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      photoUrl = await snapshot.ref.getDownloadURL();
      UserChat updateInfo = UserChat(
          id: id,
          photoUrl: photoUrl,
          nickName: nickname,
          aboutMe: aboutMe,
          phoneNumber: phoneNumber);
      settingProvider
          .updateDataFireStore(
              FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
          .then((data) async {
        await settingProvider.setPref(FirestoreConstants.photoUrl, photoUrl);
        setState(() {
          isLoading = false;
        });
      }).catchError((e) {
        Fluttertoast.showToast(msg: e.toString());
        setState(() {
          isLoading = false;
        });
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  void handleUpdateData() {
    print(controller.text);
    focusNodeNickName.unfocus();
    focusNodeAboutMe.unfocus();
    setState(() {
      isLoading = true;
      if (controller.text != "") {
        phoneNumber = dialCode + controller.text.toString();
      }
    });
    UserChat updateInfo = UserChat(
        id: id,
        photoUrl: photoUrl,
        nickName: nickname,
        aboutMe: aboutMe,
        phoneNumber: phoneNumber);
    settingProvider
        .updateDataFireStore(
            FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
        .then((data) async {
      await settingProvider.setPref(FirestoreConstants.nickname, nickname);
      await settingProvider.setPref(FirestoreConstants.aboutMe, aboutMe);
      await settingProvider.setPref(
          FirestoreConstants.phoneNumber, phoneNumber);
      await settingProvider.setPref(FirestoreConstants.photoUrl, photoUrl);

      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: "Updated");
    }).catchError((e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoButton(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  child: avatarImageFile == null
                      ? photoUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(45),
                              child: Image.network(
                                photoUrl,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (context, object, stackTrace) {
                                  return const Icon(
                                    Icons.account_circle,
                                    size: 90,
                                    color: ColorConstants.greyColor,
                                  );
                                },
                                loadingBuilder: (context, Widget child,
                                    ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) {
                                    return child;
                                  }
                                  return SizedBox(
                                    width: 90,
                                    height: 90,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.grey,
                                        value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null &&
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.account_circle,
                              size: 90,
                              color: ColorConstants.greyColor,
                            )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(45),
                          child: Image.file(
                            avatarImageFile!,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
                onPressed: getImage,
              ),
              Column(
                children: [
                  Container(
                    child: const Text("Name"),
                    margin: const EdgeInsets.only(left: 10, top: 10, bottom: 5),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(primaryColor: ColorConstants.primaryColor),
                      child: TextField(
                        controller: nickNameController,
                        onChanged: (val) {
                          nickname = val;
                        },
                        focusNode: focusNodeNickName,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                        decoration: const InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: ColorConstants.greyColor2,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: ColorConstants.primaryColor,
                            ),
                          ),
                          hintText: "Enter your name ...",
                          contentPadding: EdgeInsets.all(5),
                          hintStyle: TextStyle(
                            color: ColorConstants.greyColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    child: const Text("About Me"),
                    margin: const EdgeInsets.only(left: 10, top: 10, bottom: 5),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(primaryColor: ColorConstants.primaryColor),
                      child: TextField(
                        controller: aboutMeController,
                        onChanged: (val) {
                          aboutMe = val;
                        },
                        focusNode: focusNodeAboutMe,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                        decoration: const InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: ColorConstants.greyColor2,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: ColorConstants.primaryColor,
                            ),
                          ),
                          hintText: "Enter about you ...",
                          contentPadding: EdgeInsets.all(5),
                          hintStyle: TextStyle(
                            color: ColorConstants.greyColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    child: const Text("Phone No"),
                    margin: const EdgeInsets.only(left: 10, top: 10, bottom: 5),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(primaryColor: ColorConstants.primaryColor),
                      child: TextField(
                        enabled: false,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                        decoration: InputDecoration(
                          hintText: phoneNumber,
                          contentPadding: const EdgeInsets.all(5),
                          hintStyle: const TextStyle(
                            color: ColorConstants.greyColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 10, top: 30, bottom: 5),
                    child: SizedBox(
                      height: 60,
                      width: 400,
                      child: CountryCodePicker(
                        onChanged: (val) {
                          setState(() {
                            dialCode = val.dialCode!;
                          });
                        },
                        initialSelection: 'BD',
                        favorite: const ['+91', 'IN', '+88', 'BD'],
                        showCountryOnly: false,
                        showOnlyCountryWhenClosed: false,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    child: TextField(
                      maxLength: 12,
                      keyboardType: TextInputType.number,
                      controller: controller,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                      decoration: InputDecoration(
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: ColorConstants.greyColor2,
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: ColorConstants.greyColor,
                          ),
                        ),
                        prefix: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            dialCode,
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        hintText: "Enter phone no ...",
                        contentPadding: const EdgeInsets.all(5),
                        hintStyle: const TextStyle(
                          color: ColorConstants.greyColor,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 50),
                    child: TextButton(
                      onPressed: handleUpdateData,
                      child: const Text(
                        "Update now",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                            ColorConstants.primaryColor),
                        padding: MaterialStateProperty.all<EdgeInsets>(
                          const EdgeInsets.fromLTRB(30, 10, 30, 10),
                        ),
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
        Positioned(
          child: isLoading ? LoadingView() : const SizedBox.shrink(),
        )
      ],
    );
  }
}
