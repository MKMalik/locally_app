import 'package:LocalStory/model/story_model.dart';
import 'package:LocalStory/model/user_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:geoflutterfire/geoflutterfire.dart';

enum AppState { initial, authenticated, authenticating, unauthenticated }
enum StoryPostingState { initial, posting, posted, failed }

class LoginProvider with ChangeNotifier {
  FirebaseAuth _auth;
  var _user;
  FirebaseAuth _firebaseAuth;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
  final geo = Geoflutterfire();

  final GoogleSignIn _googleSignIn;
  AppState _appState = AppState.initial;
  StoryPostingState _storyPostingState = StoryPostingState.initial;

  AppState get appState => _appState;
  get user => _user;

  Future<Position> getCurrentLocation() async {
    Position _currentLocation;
    await geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      _currentLocation = position;
    });
    return _currentLocation;
  }

  LoginProvider.instance(this._googleSignIn) : _auth = FirebaseAuth.instance {
    _auth.authStateChanges().listen((firebaseUser) {
      if (firebaseUser == null) {
        _appState = AppState.unauthenticated;
      } else {
        print('logged In');
        _user = firebaseUser;
        _appState = AppState.authenticated;
      }

      notifyListeners();
    });
  }

  Future<bool> isSignedIn() async {
    final currentUser = _firebaseAuth.currentUser;
    return currentUser != null;
  }

  // Function to get the user and userId
  // Future<String> getUser() async {
  //   return (await _firebaseAuth.currentUser).uid;
  // }

  final GoogleSignIn googleSignIn = GoogleSignIn();

  Future<User> signInWithGoogle() async {
    _appState = AppState.authenticating;
    notifyListeners();
    await Firebase.initializeApp();

    final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final UserCredential authResult =
        await _auth.signInWithCredential(credential);
    final User user = authResult.user;

    if (user != null) {
      assert(!user.isAnonymous);
      assert(await user.getIdToken() != null);

      final User currentUser = _auth.currentUser;
      assert(user.uid == currentUser.uid);

      print('signInWithGoogle succeeded: $user');

      print("User's name: " + user.displayName);

      return user;
    }

    return null;
  }

  Future<bool> isFirstTime(String userId) async {
    bool exist;
    await _firestore
        .collection('users')
        .doc(userId)
        .get()
        .then((DocumentSnapshot user) {
      exist = user.exists;
    }).catchError((error) {
      exist = true;
    });

    return exist;
  }

  Future<bool> login(String email, String password) async {
    try {
      _appState = AppState.authenticating; //set current state to loading state.
      notifyListeners();

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      _appState = AppState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _appState = AppState.unauthenticated;
    notifyListeners();
    return Future.delayed(Duration.zero);
  }

  Future<DocumentSnapshot> getCurrentUserDetails() async {
    var _user = _firestore
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser.uid)
        .get();

    // _user.map((userData) async => {
    //       print(await userData.data()['createdAt']),
    //       userModel.createdAt = await userData.data()['createdAt'],
    //       userModel.displayName = await userData.data()['displayName'],
    //       userModel.email = await userData.data()['email'],
    //       userModel.location = await userData.data()['location'],
    //       userModel.photoUrl = await userData.data()['photoUrl'],
    //       userModel.reportedBy = await userData.data()['reportedBy'],
    //       userModel.totalStoryPosted =
    //           await userData.data()['totalStoryPosted'],
    //       userModel.userId = await userData.data()['userId'],
    //     });
    return _user;
  }

  // ***************** Story Posting and retreiving ***************** //

  Future<bool> addTextStory({String postText, String userId}) async {
    bool sent;
    String storyId = Uuid().v4();
    Position location = await getCurrentLocation();
    GeoFirePoint userLocation =
        geo.point(latitude: location.latitude, longitude: location.longitude);

    await _firestore.collection('stories').doc(storyId).set({
      'storyId': storyId,
      'senderName': user.displayName,
      'senderUid': userId,
      'senderPhotoUrl': user.photoURL,
      'createdAt': DateTime.now(),
      'type': 'Text',
      'story':
          postText, // the actual story (i.e, content) which will be shown on story page
      'likedBy': [],
      'repoetedBy': [],
      'location': userLocation.data,
    }) //storing storyId in user's data
        .then((res) {
      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('stories')
          .doc(storyId)
          .set({
        'createdAt': DateTime.now(),
        'removeAt': DateTime.now().add(Duration(hours: 24)),
      });
      sent = true;

      // **************** increase the totalStoryPosted count +1
      _firestore.runTransaction((transaction) async {
        var docRef = _firestore.collection('users').doc(userId);
        var snapshot = await transaction.get(docRef);

        int totalStoryPostedCount = snapshot.data()['totalStoryPosted'] + 1;

        transaction.update(docRef, {'totalStoryPosted': totalStoryPostedCount});

        return totalStoryPostedCount;
      });
    }).catchError((error) {
      print(error.toString() + 'text story error');
      sent = false;
    });
    return sent;
  }

  Future<bool> addImageStory(
      {String imageLink, String userId, String storyId}) async {
    bool sent;
    Position location = await getCurrentLocation();
    GeoFirePoint userLocation =
        geo.point(latitude: location.latitude, longitude: location.longitude);

    await _firestore.collection('stories').doc(storyId).set({
      'storyId': storyId,
      'senderName': user.displayName,
      'senderUid': userId,
      'senderPhotoUrl': user.photoURL,
      'createdAt': DateTime.now(),
      'type': 'Image',
      'story':
          imageLink, // the actual story (i.e, content) which will be shown on story page
      'likedBy': [],
      'repoetedBy': [],
      'location': userLocation.data,
      // TODO: put verificationLevel to user model
      // 'verificationLevel':
      //     'none', // ['none', 'verified', 'popular', 'journalist', 'celeb', 'politician']
    }) //storing storyId in user's data
        .then((res) async {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('stories')
          .doc(storyId)
          .set({
        'createdAt': DateTime.now(),
        'removeAt': DateTime.now().add(Duration(hours: 24)),
      }).then((res) {});
      sent = true;

      // **************** increase the totalStoryPosted count +1
      await _firestore.runTransaction((transaction) async {
        var docRef = _firestore.collection('users').doc(userId);
        var snapshot = await transaction.get(docRef);

        int totalStoryPostedCount =
            await snapshot.data()['totalStoryPosted'] + 1;

        // transaction.update(docRef, {'totalStoryPosted': totalStoryPostedCount});

        return totalStoryPostedCount;
      });
    }).catchError((error) {
      print(error);
      sent = false;
    });
    return sent;
  }

  Future<void> likeStory({String storyId, String userId}) async {
    // userId is for who likes the story

    // **************** append the userId in the likedBy list
    await _firestore.runTransaction(
      (transaction) async {
        var docRef = _firestore.collection('stories').doc(storyId);
        var snapshot = await transaction.get(docRef);

        List<dynamic> likedByList = snapshot.data()['likedBy'] as List;

        if (likedByList != null) {
          if (!likedByList.contains(userId)) {
            likedByList.add(userId);
          }
        } else {
          likedByList = [userId];
        }

        transaction.update(docRef, {'likedBy': likedByList});

        return likedByList;
      },
    );
  }

  Future<bool> isStoryLiked({String storyId, String currentUserId}) async {
    bool isLiked;
    await _firestore.runTransaction((transaction) async {
      var docRef = _firestore.collection('stories').doc(storyId);
      var snapshot = await transaction.get(docRef);

      List<dynamic> likedByList = snapshot.data()['likedBy'] as List;

      isLiked = likedByList.contains(currentUserId);
    });

    return isLiked;
  }

  Future<void> unlikeStory({String storyId, String userId}) async {
    // userId is for who likes the story

    // **************** append the userId in the likedBy list
    await _firestore.runTransaction((transaction) async {
      var docRef = _firestore.collection('stories').doc(storyId);
      var snapshot = await transaction.get(docRef);

      List<dynamic> likedByList = snapshot.data()['likedBy'] as List;

      if (likedByList != null) {
        if (likedByList.contains(userId)) {
          likedByList.remove(userId);
        }
      }

      transaction.update(docRef, {'likedBy': likedByList});

      return likedByList;
    });
  }
}
