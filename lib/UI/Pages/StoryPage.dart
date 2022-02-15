import 'dart:ui';
import 'package:LocalStory/UI/Pages/AddStory.dart';
import 'package:LocalStory/UI/Pages/SettingPage.dart';
import 'package:LocalStory/constant.dart';
import 'package:LocalStory/model/story_model.dart';
import 'package:LocalStory/model/story_repository.dart';
// import 'package:LocalStory/functions/getLocation.dart';
import 'package:LocalStory/model/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:get_time_ago/get_time_ago.dart';

class StoryPage extends StatefulWidget {
  final user;
  StoryPage({this.user});
  @override
  _StoryPageState createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
  User currentUser = FirebaseAuth.instance.currentUser;

  final geo = Geoflutterfire();

  void updateCurrentLocation() {
    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position location) {
      GeoFirePoint userLocation =
          geo.point(latitude: location.latitude, longitude: location.longitude);
      _firestore.collection("users").doc(currentUser.uid).update({
        'location': userLocation.data,
      }).then((res) => print('location updated'));
    });
  }

  GeoFirePoint center;
  PhotoViewScaleStateController photoViewScaleStateController;

  @override
  void initState() {
    final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((currentPostion) {
      center = geo.point(
          latitude: currentPostion.latitude,
          longitude: currentPostion.longitude);
      setState(() {});
    });

    photoViewScaleStateController = PhotoViewScaleStateController();

    super.initState();
  }

  @override
  void dispose() {
    photoViewScaleStateController.dispose();
    super.dispose();
  }

  double radius = 10.0; // users in 10 km of radius can see stories

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<LoginProvider>(context);
    final storyProvider = Provider.of<StoryProvider>(context);

    updateCurrentLocation();

    Future<Position> getCurrentLocaion() async {
      return await storyProvider.getCurrentLocation();
    }

    likeStory({userId, storyId}) {
      user.likeStory(storyId: storyId, userId: userId);
    }

    unlikeStory({userId, storyId}) {
      user.unlikeStory(storyId: storyId, userId: userId);
    }

    isStoryLiked({storyId}) async {
      return await user.isStoryLiked(
          currentUserId: currentUser.uid, storyId: storyId);
    }

    currentUserData() async {
      var current_user = await user.getCurrentUserDetails();
      return current_user.data();
    }

    Size size = MediaQuery.of(context).size;
    getCurrentLocaion().then((currentPostion) {
      center = geo.point(
          latitude: currentPostion.latitude,
          longitude: currentPostion.longitude);
    });
    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(color: backgroundColor),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SizedBox(),
                ),
                Container(
                  height: size.height * 0.55,
                  child: SvgPicture.asset('Assets/background.svg'),
                ),
              ],
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            currentUserData();
                          },
                          child: Text(
                            'Locally',
                            style: GoogleFonts.coda(
                                textStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: size.width * 0.08)),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(PageRouteBuilder(
                                transitionDuration: Duration(milliseconds: 250),
                                pageBuilder: (context, animation, animation1) {
                                  return SettingPage();
                                },
                                transitionsBuilder: (BuildContext context,
                                    Animation<double> animation,
                                    Animation<double> secondaryAnimation,
                                    Widget child) {
                                  return Align(
                                    // here you can try other transition types to changes animation (i.e., ScaleTransition, FadeTransition)
                                    child: FadeTransition(
                                      opacity: animation,
                                      // sizeFactor: animation,
                                      child: child,
                                    ),
                                  );
                                }));
                          },
                        )
                      ],
                    ),
                  ),
                  // SizedBox(
                  //   height: size.height * 0.06,
                  // ),
                  Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text(
                      'Near you',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width * 0.05,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: size.width * 0.9,
                      height: size.height * 0.8,
                      child: center != null
                          ? StreamBuilder<List<DocumentSnapshot>>(
                              key: GlobalKey(),
                              // stream: storyProvider.stories,
                              stream: Geoflutterfire()
                                  .collection(
                                      collectionRef:
                                          _firestore.collection('stories'))
                                  .within(
                                      center: center,
                                      radius: radius,
                                      field: 'location'),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator());
                                }

                                if (snapshot.data.isEmpty) {
                                  return Container(
                                    margin: EdgeInsets.all(8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                          size.width * 0.03),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 20, sigmaY: 20),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white70,
                                          ),
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: SizedBox(),
                                              ),
                                              Center(
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      horizontal: 20,
                                                      vertical: 10),
                                                  child: Text(
                                                    'No stories available nearby\nAdd one yourself.',
                                                    style: TextStyle(
                                                        fontSize:
                                                            size.width * 0.06,
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: SizedBox(),
                                              ),
                                              Container(
                                                padding: EdgeInsets.all(10),
                                                height: size.height * 0.065,
                                                decoration: BoxDecoration(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return PageView.builder(
                                  scrollDirection: Axis.vertical,
                                  restorationId: 'restore',
                                  controller: PageController(
                                    keepPage: true, // TODO: check what it does
                                    viewportFraction: 0.95,
                                  ),
                                  itemCount: snapshot.data.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return GestureDetector(
                                      onLongPress: () {
                                        print('unlike');
                                        unlikeStory(
                                            storyId: snapshot.data[index]
                                                ['storyId'],
                                            userId: currentUser.uid);
                                      },
                                      onDoubleTap: () {
                                        print('like');
                                        print(snapshot.data[index]['storyId']);
                                        likeStory(
                                            storyId: snapshot.data[index]
                                                ['storyId'],
                                            userId: currentUser.uid);
                                      },
                                      child: storyCarousel(
                                        index: index,
                                        size: size,
                                        story: snapshot.data[index]
                                            .data()['story'],
                                        type:
                                            snapshot.data[index].data()['type'],
                                        senderName: snapshot.data[index]
                                            .data()['senderName'],
                                        senderUid: snapshot.data[index]
                                            .data()['senderUid'],
                                        senderPhotoUrl: snapshot.data[index]
                                            .data()['senderPhotoUrl'],
                                        storyId: snapshot.data[index]
                                            .data()['storyId'],
                                        createdAt: snapshot.data[index]
                                            .data()['createdAt'],
                                        geopoint: snapshot.data[index]
                                            .data()['location']['geopoint'],
                                        likesList: snapshot.data[index]
                                            ['likedBy'],
                                      ),
                                    );
                                  },
                                );
                              })
                          : Center(
                              child: CircularProgressIndicator(),
                            ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Row(
          children: [
            Icon(
              Icons.add_to_photos,
              color: Colors.black,
            ),
            SizedBox(
              width: size.width * 0.02,
            ),
            Text(
              'Add story',
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
        onPressed: () {
          Navigator.of(context).push(PageRouteBuilder(
              transitionDuration: Duration(milliseconds: 250),
              pageBuilder: (context, animation, animation1) {
                return AddStory();
              },
              transitionsBuilder: (BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                  Widget child) {
                return Align(
                  // here you can try other transition types to changes animation (i.e., ScaleTransition, FadeTransition)
                  child: SizeTransition(
                    sizeFactor: animation,
                    // sizeFactor: animation,
                    child: child,
                  ),
                );
              }));
        },
        backgroundColor: Colors.white,
      ),
    );
  }

  Future<void> deleteStory(
      {String storyId, String senderUid, String type, String story}) async {
    if (type == 'Text') {
      await _firestore.collection('stories').doc(storyId).delete();
      await _firestore
          .collection('users')
          .doc(senderUid)
          .collection('stories')
          .doc(storyId)
          .delete();
    } else if (type == 'Image') {
      await _firestore.collection('stories').doc(storyId).delete();
      await _firestore
          .collection('users')
          .doc(senderUid)
          .collection('stories')
          .doc(storyId)
          .delete();

      FirebaseStorage.instance.ref().child(senderUid).child(storyId).delete();
    }
  }

  Widget storyCarousel({
    int index,
    Size size,
    String type,
    String senderName,
    String senderUid,
    String senderPhotoUrl,
    Timestamp createdAt,
    String story,
    String storyId,
    var geopoint,
    int numberOfLikes,
    List<dynamic> likesList,
  }) {
    Widget storyCard;
    double heartSize = size.width * 0.15;
    Widget likeStoryWidget = Positioned(
      bottom: size.height * 0.1,
      right: 10,
      child: GestureDetector(
        onTap: () {
          // shrink heart size
          LoginProvider.instance(GoogleSignIn())
              .unlikeStory(storyId: storyId, userId: currentUser.uid);
        },
        child: Icon(FontAwesomeIcons.solidHeart,
            size: heartSize, color: Colors.redAccent),
      ),
    );
    if (type == 'Text') {
      storyCard = Stack(
        children: [
          Container(
            margin: EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size.width * 0.03),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white70,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: SizedBox(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Container(
                          // width: size.width,
                          height: size.height / 4,
                          child: SingleChildScrollView(
                            child: Text(
                              story,
                              softWrap: true,
                              style: TextStyle(
                                fontSize: size.width * 0.06,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SizedBox(),
                      ),
                      Container(
                        padding: EdgeInsets.all(10),
                        height: size.height * 0.08,
                        decoration: BoxDecoration(
                          color: Colors.white70,
                        ),
                        child: storySenderDetails(
                          senderPhotoUrl: senderPhotoUrl,
                          senderName: senderName,
                          size: size,
                          createdAt: createdAt,
                          center: center,
                          geopoint: geopoint,
                          numberOfLikes: likesList.length,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          currentUser.uid == senderUid
              ? Positioned(
                  right: 20,
                  top: 20,
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        child: AlertDialog(
                          title: Text('Delete story'),
                          content: Text('This action is irreversable'),
                          actions: [
                            TextButton(
                              child: Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () {
                                deleteStory(
                                    senderUid: senderUid,
                                    storyId: storyId,
                                    type: type);
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    child: SvgPicture.asset(
                      'Assets/delete.svg',
                      height: size.width * 0.07,
                    ),
                  ),
                )
              : SizedBox(),
          if (likesList.contains(currentUser.uid)) likeStoryWidget,
        ],
      );
    } else {
      NetworkImage _image = NetworkImage(story);
      storyCard = Stack(
        children: [
          GestureDetector(
            onTap: () {
              print('photo view');
              Navigator.of(context).push(PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 250),
                  pageBuilder: (context, animation, animation1) {
                    return Stack(
                      children: [
                        PhotoView(
                          initialScale: PhotoViewComputedScale.contained,
                          minScale: PhotoViewComputedScale.contained,
                          maxScale: PhotoViewComputedScale.covered * 2,
                          scaleStateController: photoViewScaleStateController,
                          imageProvider: _image,
                        ),
                        Positioned(
                          left: 10,
                          top: 10,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  transitionsBuilder: (BuildContext context,
                      Animation<double> animation,
                      Animation<double> secondaryAnimation,
                      Widget child) {
                    return Align(
                      // here you can try other transition types to changes animation (i.e., ScaleTransition, FadeTransition)
                      child: FadeTransition(
                        opacity: animation,
                        // sizeFactor: animation,
                        child: child,
                      ),
                    );
                  }));
              // Navigator.of(context).push(MaterialPageRoute(
              //   builder: (context) =>
              // ));
            },
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                    image: NetworkImage(story), fit: BoxFit.cover),
                borderRadius: BorderRadius.circular(size.width * 0.03),
              ),
              margin: EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(size.width * 0.03),
                child: Column(
                  children: [
                    Expanded(
                      child: SizedBox(),
                    ),
                    Container(),
                    Expanded(
                      child: SizedBox(),
                    ),
                    Container(
                      padding: EdgeInsets.all(10),
                      height: size.height * 0.08,
                      decoration: BoxDecoration(
                        color: Colors.white70,
                      ),
                      child: storySenderDetails(
                        senderPhotoUrl: senderPhotoUrl,
                        senderName: senderName,
                        size: size,
                        createdAt: createdAt,
                        center: center,
                        geopoint: geopoint,
                        numberOfLikes: likesList.length,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          currentUser.uid == senderUid
              ? Positioned(
                  right: 20,
                  top: 20,
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        child: AlertDialog(
                          title: Text('Delete story'),
                          content: Text('This action is irreversable'),
                          actions: [
                            TextButton(
                              child: Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () {
                                deleteStory(
                                    senderUid: senderUid,
                                    storyId: storyId,
                                    type: type);
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    child: SvgPicture.asset(
                      'Assets/delete.svg',
                      height: size.width * 0.07,
                    ),
                  ),
                )
              : SizedBox(),
          if (likesList.contains(currentUser.uid)) likeStoryWidget,
        ],
      );
    }

    return storyCard;
  }

  String calcucateDistance({var center, var geopoint}) {
    var latitude = geopoint.latitude;
    var longitude = geopoint.longitude;
    double distance = center.distance(lat: latitude, lng: longitude);
    int distanceResult;
    String suffix;

    if (distance < 1) {
      distanceResult = (distance * 1000).toInt();
      suffix = 'meter away';
    } else {
      distanceResult = distance.toInt();
      suffix = 'km away';
    }

    if (distanceResult < 0.5) return 'From your neighbour';

    return '$distanceResult $suffix';
  }

  Widget storySenderDetails({
    String senderPhotoUrl,
    String senderName,
    Size size,
    Timestamp createdAt,
    var geopoint,
    var center,
    int numberOfLikes,
  }) {
    String distance = calcucateDistance(center: center, geopoint: geopoint);
    // print(distance);
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(senderPhotoUrl),
        ),
        SizedBox(
          width: 10,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                '$senderName',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: backgroundColor,
                    fontSize: size.width * 0.06,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Text(distance.toString()),
          ],
        ),
        Expanded(
          child: SizedBox(),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              TimeAgo.getTimeAgo(createdAt.toDate()),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Likes: $numberOfLikes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            // LikeButton(
            //   size: size.width * 0.05,
            //   circleColor:
            //       const CircleColor(start: Colors.red, end: Colors.orange),
            //   // isLiked: isStoryLiked,
            // ),
          ],
        ),
      ],
    );
  }
}
