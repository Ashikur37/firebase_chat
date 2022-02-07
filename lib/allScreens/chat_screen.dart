import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_social/allConstants/constants.dart';
import 'package:flutter_social/allModels/message_chat.dart';
import 'package:flutter_social/allProviders/auth_provider.dart';
import 'package:flutter_social/allProviders/setting_provider.dart';
import 'package:flutter_social/allScreens/full_photo_page.dart';
import 'package:flutter_social/allScreens/home_screen.dart';
import 'package:flutter_social/allWidgets/widgets.dart';
import 'package:flutter_social/main.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import '../allProviders/chat_provider.dart';
import 'full_photo.dart';
import 'login_screen.dart';

typedef _Fn = void Function();
const theSource = AudioSource.microphone;

class ChatPage extends StatefulWidget {
  final String peerId;
  final String peerNickName;
  final String peerAvatar;
  const ChatPage(
      {Key? key,
      required this.peerId,
      required this.peerNickName,
      required this.peerAvatar})
      : super(key: key);

  @override
  // ignore: no_logic_in_create_state
  ChatPageState createState() => ChatPageState(
        peerId: peerId,
        peerNickName: peerNickName,
        peerAvatar: peerAvatar,
      );
}

class ChatPageState extends State<ChatPage> {
  ChatPageState(
      {required this.peerId,
      required this.peerNickName,
      required this.peerAvatar});

  String peerId;
  String peerNickName;
  String peerAvatar;
  late String currentUserId;

  int _limit = 20;
  int _limitIncrement = 20;
  List<QueryDocumentSnapshot> listMessage = List.from([]);
  String groupChatId = "";

  File? imageFile;
  String imageUrl = "";
  bool isLoading = false;
  bool isShowSticker = false;

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();
  final FocusNode focusNode = FocusNode();
  late ChatProvider chatProvider;
  late AuthProvider authProvider;
  Codec _codec = Codec.aacMP4;
  String _mPath = 'tau_file.mp4';
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  FlutterSoundRecorder? _mRecorder = FlutterSoundRecorder();
  bool _mPlayerIsInited = false;
  bool _mRecorderIsInited = false;
  bool _mplaybackReady = false;

  @override
  void initState() {
    super.initState();
    chatProvider = context.read<ChatProvider>();
    authProvider = context.read<AuthProvider>();

    focusNode.addListener(onFocusChange);
    listScrollController.addListener(_scrollListener);
    readLocal();
    _mPlayer!.openPlayer().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });

    openTheRecorder().then((value) {
      setState(() {
        _mRecorderIsInited = true;
      });
    });
  }

  Future<void> openTheRecorder() async {
    if (!kIsWeb) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
    }
    await _mRecorder!.openRecorder();
    if (!await _mRecorder!.isEncoderSupported(_codec) && kIsWeb) {
      _codec = Codec.opusWebM;
      _mPath = 'tau_file.webm';
      if (!await _mRecorder!.isEncoderSupported(_codec) && kIsWeb) {
        _mRecorderIsInited = true;
        return;
      }
    }
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));

    _mRecorderIsInited = true;
  }

  void record() {
    _mRecorder!
        .startRecorder(
      toFile: _mPath,
      codec: _codec,
      audioSource: theSource,
    )
        .then((value) {
      setState(() {});
    });
  }

  void stopRecorder() async {
    await _mRecorder!.stopRecorder().then((value) {
      setState(() {
        //var url = value;
        _mplaybackReady = true;
      });
    });
  }

  void play() {
    assert(_mPlayerIsInited &&
        _mplaybackReady &&
        _mRecorder!.isStopped &&
        _mPlayer!.isStopped);
    _mPlayer!
        .startPlayer(
            fromURI: _mPath,
            //codec: kIsWeb ? Codec.opusWebM : Codec.aacADTS,
            whenFinished: () {
              setState(() {});
            })
        .then((value) {
      setState(() {});
    });
  }

  void stopPlayer() {
    _mPlayer!.stopPlayer().then((value) {
      setState(() {});
    });
  }

// ----------------------------- UI --------------------------------------------

  _Fn? getRecorderFn() {
    if (!_mRecorderIsInited || !_mPlayer!.isStopped) {
      return null;
    }
    return _mRecorder!.isStopped ? record : stopRecorder;
  }

  _Fn? getPlaybackFn() {
    if (!_mPlayerIsInited || !_mplaybackReady || !_mRecorder!.isStopped) {
      return null;
    }
    return _mPlayer!.isStopped ? play : stopPlayer;
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

  void onFocusChange() {
    if (focusNode.hasFocus) {
      setState(() {
        isShowSticker = false;
      });
    }
  }

  void readLocal() {
    if (authProvider.getFirebaseUserId()?.isNotEmpty == true) {
      currentUserId = authProvider.getFirebaseUserId()!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
          (Route<dynamic> route) => false);
    }
    if (currentUserId.hashCode <= peerId.hashCode) {
      groupChatId = '$currentUserId-$peerId';
    } else {
      groupChatId = '$peerId-$currentUserId';
    }
    chatProvider.updateDataFirestore(
      FirestoreConstants.pathUserCollection,
      currentUserId,
      {
        FirestoreConstants.chattingWith: peerId,
      },
    );
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
        isLoading = true;
      });
      uploadFile();
    }
  }

  void getSticker() {
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }

  void recordAudio() {}

  Future uploadFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    UploadTask uploadTask = chatProvider.uploadTask(imageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, TypeMessage.image);
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  void onSendMessage(String content, int type) {
    if (content.trim().isNotEmpty) {
      textEditingController.clear();
      chatProvider.sendMessage(
          content, type, groupChatId, currentUserId, peerId);
      listScrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  bool isLastMessageLeft(int index) {
    if (index > 0 &&
            listMessage[index - 1].get(FirestoreConstants.idFrom) ==
                currentUserId ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
        listMessage[index - 1].get(FirestoreConstants.idFrom) !=
            currentUserId)) {
      return true;
    } else {
      return false;
    }
  }

  void _callPhoneNumber(String callPhoneNumber) async {
    if (callPhoneNumber.isNotEmpty) {
      String url = "tel:$callPhoneNumber";
      await launch(url);
    } else {
      Fluttertoast.showToast(msg: "Phone number not available");
    }
  }

  Future<bool> onBackPress() {
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {
      chatProvider.updateDataFirestore(FirestoreConstants.pathUserCollection,
          currentUserId, {FirestoreConstants.chattingWith: null});
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    }
    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isWhite ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: isWhite ? Colors.white : Colors.grey[900],
        iconTheme: const IconThemeData(
          color: ColorConstants.primaryColor,
        ),
        title: Text(
          peerNickName,
          style: const TextStyle(
            color: ColorConstants.primaryColor,
          ),
        ),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.phone_iphone,
              size: 30,
              color: ColorConstants.primaryColor,
            ),
            onPressed: () {
              SettingProvider settingProvider;
              settingProvider = context.read<SettingProvider>();
              String callPhoneNumber =
                  settingProvider.getPref(FirestoreConstants.phoneNumber) ?? "";
              _callPhoneNumber(callPhoneNumber);
            },
          ),
        ],
      ),
      body: WillPopScope(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                // List of messages
                buildListMessage(),
                // Sticker
                (isShowSticker ? buildSticker() : Container()),
                // Input content
                buildInput(),
              ],
            ),
            // Loading
            (isLoading ? LoadingView() : Container()),
          ],
        ),
        onWillPop: onBackPress,
      ),
    );
  }

  Widget buildSticker() {
    return Expanded(
      child: Container(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => onSendMessage('mimi1', TypeMessage.sticker),
                  child: Image.asset(
                    'images/mimi1.gif',
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi2', TypeMessage.sticker),
                  child: Image.asset(
                    'images/mimi2.gif',
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi3', TypeMessage.sticker),
                  child: Image.asset(
                    'images/mimi3.gif',
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => onSendMessage('mimi4', TypeMessage.sticker),
                  child: Image.asset(
                    'images/mimi4.gif',
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi5', TypeMessage.sticker),
                  child: Image.asset(
                    'images/mimi5.gif',
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi6', TypeMessage.sticker),
                  child: Image.asset(
                    'images/mimi6.gif',
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => onSendMessage('mimi7', TypeMessage.sticker),
                  child: Image.asset(
                    'images/mimi7.gif',
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi8', TypeMessage.sticker),
                  child: Image.asset(
                    'images/mimi8.gif',
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => onSendMessage('mimi9', TypeMessage.sticker),
                  child: Image.asset(
                    'images/mimi9.gif',
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            )
          ],
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        ),
        decoration: const BoxDecoration(
          border: Border(
              top: BorderSide(
            color: Colors.grey,
            width: 0.5,
          )),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(5),
        height: 180.0,
      ),
    );
  }

  Widget buildInput() {
    return Container(
      child: Row(
        children: [
          // Button send image
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
          // Button send message
          Material(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(
                icon: const Icon(Icons.face),
                onPressed: getSticker,
                color: Colors.blue,
              ),
            ),
            color: Colors.white,
          ),
          // Edit text
          Flexible(
            child: Container(
              child: TextField(
                style: const TextStyle(color: Colors.black, fontSize: 15.0),
                controller: textEditingController,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(
                    color: ColorConstants.greyColor,
                  ),
                ),
                focusNode: focusNode,
              ),
            ),
          ),
          // Button send message
          Material(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () =>
                    onSendMessage(textEditingController.text, TypeMessage.text),
                color: Colors.blue,
              ),
            ),
            color: Colors.white,
          ),
        ],
      ),
      width: double.infinity,
      height: 50.0,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: ColorConstants.greyColor2, width: 0.5),
        ),
        color: Colors.white,
      ),
    );
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading ? LoadingView() : const SizedBox.shrink(),
    );
  }

  Widget buildItem(int index, DocumentSnapshot? document) {
    if (document != null) {
      MessageChat messageChat = MessageChat.fromDocument(document);
      if (messageChat.idFrom == currentUserId) {
        return Row(
          children: [
            messageChat.type == TypeMessage.text
                ? Container(
                    child: Text(
                      messageChat.content,
                      style: const TextStyle(
                        color: ColorConstants.primaryColor,
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: EdgeInsets.only(
                      bottom: isLastMessageRight(index) ? 20 : 10,
                      right: 10,
                    ),
                  )
                : messageChat.type == TypeMessage.image
                    ? Container(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => FullPhotoPage(
                                        url: messageChat.content)));
                          },
                          child: Material(
                            child: Image.network(
                              messageChat.content,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                      color: ColorConstants.greyColor2,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        color: Theme.of(context).primaryColor,
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
                                            : null),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Material(
                                  child: Image.asset(
                                    "images/img_not_available.jpeg",
                                    fit: BoxFit.cover,
                                    width: 200,
                                    height: 200,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  clipBehavior: Clip.hardEdge,
                                );
                              },
                              fit: BoxFit.cover,
                              height: 200,
                              width: 200,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            clipBehavior: Clip.hardEdge,
                          ),
                          style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero),
                        ),
                        margin: EdgeInsets.only(
                            bottom: isLastMessageRight(index) ? 2 : 4,
                            top: 4,
                            right: 10),
                      )
                    : Container(
                        child: Image.asset(
                          "images/${messageChat.content}.gif",
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                        margin: EdgeInsets.only(
                            bottom: isLastMessageRight(index) ? 2 : 4,
                            top: 4,
                            right: 10),
                      ),
          ],
          mainAxisAlignment: MainAxisAlignment.end,
        );
      } else {
        return Container(
          child: Column(
            children: [
              Row(
                children: [
                  isLastMessageLeft(index)
                      ? Material(
                          child: Image.network(
                            peerAvatar,
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }
                              return Center(
                                child: CircularProgressIndicator(
                                  color: ColorConstants.themeColor,
                                  value: loadingProgress.expectedTotalBytes !=
                                              null &&
                                          loadingProgress.expectedTotalBytes !=
                                              null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, object, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.account_circle,
                                  color: ColorConstants.greyColor,
                                  size: 35,
                                ),
                              );
                            },
                            width: 35,
                            height: 35,
                            fit: BoxFit.cover,
                          ),
                          borderRadius: const BorderRadius.all(
                            const Radius.circular(18),
                          ),
                          clipBehavior: Clip.hardEdge,
                        )
                      : Container(
                          width: 35,
                        ),
                  messageChat.type == TypeMessage.text
                      ? Container(
                          child: Text(
                            messageChat.content,
                            style: const TextStyle(
                              color: ColorConstants.greyColor,
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                          width: 200,
                          decoration: BoxDecoration(
                            color: ColorConstants.greyColor2,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          margin: EdgeInsets.only(
                            bottom: isLastMessageLeft(index) ? 20 : 10,
                            left: 10,
                          ),
                        )
                      : messageChat.type == TypeMessage.image
                          ? Container(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => FullPhoto(
                                              imgUrl: messageChat.content)));
                                },
                                child: Material(
                                  child: Image.network(
                                    messageChat.content,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: 200,
                                        height: 200,
                                        decoration: BoxDecoration(
                                            color: ColorConstants.greyColor2,
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                              color: Theme.of(context)
                                                  .primaryColor,
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
                                                  : null),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Material(
                                        child: Image.asset(
                                          "images/img_not_available.jpeg",
                                          fit: BoxFit.cover,
                                          width: 200,
                                          height: 200,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        clipBehavior: Clip.hardEdge,
                                      );
                                    },
                                    fit: BoxFit.cover,
                                    height: 200,
                                    width: 200,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  clipBehavior: Clip.hardEdge,
                                ),
                                style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero),
                              ),
                              margin: EdgeInsets.only(
                                  bottom: isLastMessageRight(index) ? 2 : 4,
                                  top: 4,
                                  right: 10),
                            )
                          : Container(
                              child: Image.asset(
                                "images/${messageChat.content}.gif",
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                              margin: EdgeInsets.only(
                                  bottom: isLastMessageRight(index) ? 20 : 10,
                                  right: 10),
                            )
                ],
              ),
              isLastMessageLeft(index)
                  ? Container(
                      child: Text(
                        DateFormat('dd MMM yyyy, hh::mm a').format(
                          DateTime.fromMillisecondsSinceEpoch(
                            int.parse(
                              messageChat.timeStamp,
                            ),
                          ),
                        ),
                        style: const TextStyle(
                          color: ColorConstants.greyColor,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      margin:
                          const EdgeInsets.only(left: 50, top: 5, bottom: 5),
                    )
                  : const SizedBox.shrink(),
            ],
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
          margin: const EdgeInsets.only(bottom: 10),
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget buildListMessage() {
    return Flexible(
      child: groupChatId.isNotEmpty
          ? StreamBuilder(
              stream: chatProvider.getChatStream(groupChatId, _limit),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  listMessage.addAll(snapshot.data!.docs);
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
              })
          : const Center(
              child: const CircularProgressIndicator(),
            ),
    );
  }
}
