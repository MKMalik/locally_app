// Stream of stories in story_model form
import 'dart:async';

import 'package:LocalStory/model/story_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:geolocator/geolocator.dart';

class StoryProvider with ChangeNotifier {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Position> getCurrentLocation() async {
    Position _currentLocation;
    final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
    await geolocator
        .getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
            locationPermissionLevel: GeolocationPermission.locationWhenInUse)
        .then((Position position) {
      _currentLocation = position;
    });
    return _currentLocation;
  }

  List<StoryModel> _storyListFromSnanshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return StoryModel(
          createdAt: doc.data()['createdAt'],
          senderName: doc.data()['senderName'],
          story: doc.data()['story'],
          type: doc.data()['type']);
    }).toList();
  }

  // List<StoryModel> _storyListFromDocumentSnanshot(DocumentSnapshot snapshot) {
  //   return snapshot.data();
  // }

  Stream<List<StoryModel>> get stories {
    return _firestore
        .collection('stories')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_storyListFromSnanshot);
  }

  // Future<Stream<List<DocumentSnapshot>>> get getNearbyStories async {
  //   // Init firestore and geoFlutterFire
  //   final geo = Geoflutterfire();
  //   Position currentPostion = await getCurrentLocation();
  //   GeoFirePoint center = geo.point(
  //       latitude: currentPostion.latitude, longitude: currentPostion.longitude);

  //   var collectionReference = _firestore.collection('stories');

  //   double radius = 10.0;
  //   String field = 'location';

  //   var stream = geo
  //       .collection(collectionRef: collectionReference)
  //       .within(center: center, radius: radius, field: field);
  //   return stream;
  //   // return stream.listen((List<DocumentSnapshot> docs) {
  //   //   // docs.map(_storyListFromDocumentSnanshot);
  //   //   docs.map((doc) {
  //   //     var data = doc.data();
  //   //     return StoryModel(
  //   //       createdAt: data['createdAt'],
  //   //       senderName: data['senderName'],
  //   //       story: data['story'],
  //   //       type: data['type'],
  //   //     );
  //   //   });
  //   // });
  // }
}
