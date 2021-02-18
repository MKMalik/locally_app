import 'dart:ui';
import 'package:LocalStory/constant.dart';
import 'package:LocalStory/model/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var _user;
  bool isLoading = true;
  User currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _user = _firestore.collection('users').doc(currentUser.uid);
    setState(() {
      print(_user);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final user = Provider.of<LoginProvider>(context);

    return Scaffold(
      body: !isLoading
          ? Container(
              decoration: BoxDecoration(color: backgroundColor),
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: SizedBox(),
                      ),
                      Container(
                        // width: size.width,
                        height: size.height * 0.55,
                        child: SvgPicture.asset('Assets/background.svg'),
                      ),
                    ],
                  ),
                  SafeArea(
                    child: Column(
                      children: [
                        SizedBox(
                          height: size.height * 0.1,
                        ),

                        // profile picture
                        Container(
                          width: size.width * 0.25,
                          height: size.width * 0.25,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(size.width),
                              color: Colors.white,
                              image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(_user['photoUrl']))),
                        ),

                        SizedBox(
                          height: size.height * 0.02,
                        ),

                        //user displayName
                        Center(
                          child: Text(
                            currentUser.displayName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: size.width * 0.06,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Expanded(
                          child: SizedBox(),
                        ),

                        // logout button
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            width: size.width * 0.5,
                            height: size.height * 0.06,
                            child: RaisedButton(
                              padding: EdgeInsets.all(10),
                              onPressed: () {
                                Navigator.of(context).pop();
                                Future.delayed(
                                  Duration(milliseconds: 250),
                                ).then((res) {
                                  user.logout();
                                });
                              },
                              child: Text('Logout'),
                            ),
                          ),
                        ),

                        SizedBox(
                          height: size.height * 0.2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : CircularProgressIndicator(),
    );
  }
}
