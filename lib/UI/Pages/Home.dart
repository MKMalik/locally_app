import 'package:LocalStory/UI/Pages/LoginPage.dart';
import 'package:LocalStory/UI/Pages/StoryPage.dart';
import 'package:LocalStory/model/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return _showScreen(context);
  }
}

Widget _showScreen(BuildContext context) {
  switch (context.watch<LoginProvider>().appState) {
    case AppState.authenticating:
    case AppState.unauthenticated:
      return LoginPage();
    case AppState.initial:
      return SplashScreen();
    case AppState.authenticated:
      return StoryPage(
        user: context.watch<LoginProvider>().user,
      );
  }
  return Container();
}

// ignore: non_constant_identifier_names
Widget SplashScreen() {
  return Center(
    child: CircularProgressIndicator(),
  );
}
