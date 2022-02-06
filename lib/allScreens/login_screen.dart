import 'package:flutter/material.dart';
import 'package:flutter_social/allProviders/auth_provider.dart';
import 'package:flutter_social/allScreens/home_screen.dart';
import 'package:flutter_social/allWidgets/loading_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider = Provider.of<AuthProvider>(context);
    switch (authProvider.status) {
      case Status.authenticateError:
        Fluttertoast.showToast(msg: "Signin failed");
        break;
      case Status.authenticateCanceled:
        Fluttertoast.showToast(msg: "Signin canceled");
        break;
      case Status.athenticated:
        Fluttertoast.showToast(msg: "Signin success");
        break;
      default:
        break;
    }
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Image.asset("images/back.png"),
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: GestureDetector(
              onTap: () async {
                bool isSuccess = await authProvider.handleSignIn();
                if (isSuccess) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                  );
                }
              },
              child: Image.asset("images/google_login.jpg"),
            ),
          ),
          Positioned(
            child: authProvider.status == Status.authenticating
                ? LoadingView()
                : const SizedBox.shrink(),
          )
        ],
      ),
    );
  }
}
