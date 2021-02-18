import 'dart:ui';
import 'package:LocalStory/constant.dart';
import 'package:LocalStory/model/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
  Position _currentPosition;

  @override
  void initState() {
    super.initState();
  }

  Future<Position> getCurrentLocation() async {
    Position _currentLocation;
    await geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      _currentLocation = position;
    });
    return _currentLocation;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final _user = Provider.of<LoginProvider>(context);

    final geo = Geoflutterfire();

    void storeUserToDataBase(User user) async {
      Position location = await getCurrentLocation();
      GeoFirePoint userLocation =
          geo.point(latitude: location.latitude, longitude: location.longitude);
      _firestore
          .collection("users")
          .doc(user.uid)
          .set({
            'userId': user.uid,
            'displayName': user.displayName,
            'photoUrl': user.photoURL ?? null,
            'email': user.email,
            'createdAt': DateTime.now(),
            'reportedBy': [],
            'totalStoryPosted': 0,
            'location': userLocation.data,
          })
          .then((res) => print('data added to db'))
          .catchError((error) => {
                print(error),
              });
    }

    return Scaffold(
      body: Container(
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
            Center(
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Login',
                        style: GoogleFonts.sriracha(
                            textStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: size.width * 0.18))),

                    // continue (login) with google button
                    ClipRRect(
                      borderRadius: BorderRadius.circular(size.width * 0.04),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 8,
                          sigmaY: 8,
                        ),
                        child: GestureDetector(
                          onTap: () async {
                            _user.signInWithGoogle().then((user) async {
                              // check if user alreay exists, if not, create user data and add to db
                              // if exists, don't add any data
                              _firestore
                                  .collection('users')
                                  .doc(user.uid)
                                  .get()
                                  .then((doc) => {
                                        if (!doc.exists)
                                          storeUserToDataBase(user),
                                      });

                              print(user.uid + ' LOGGED IN');
                            });
                            // print(user.getUser().toString());
                          },
                          child: Container(
                            width: size.width * 0.65,
                            padding: EdgeInsets.all(size.width * 0.05),
                            decoration: BoxDecoration(
                              color: Colors.white54,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text(
                                  'Continue With',
                                  style: GoogleFonts.b612(
                                      textStyle: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: backgroundColor,
                                          fontSize: size.width * 0.065)),
                                ),
                                Image(
                                  width: size.width * 0.075,
                                  image: AssetImage('Assets/google.ico'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
