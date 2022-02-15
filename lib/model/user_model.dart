import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  Timestamp createdAt;
  String displayName;
  String email;
  String location;
  String photoUrl;
  String reportedBy;
  String totalStoryPosted;
  String userId;

  UserModel(this.createdAt, this.displayName, this.email, this.location,
      this.photoUrl, this.reportedBy, this.totalStoryPosted, this.userId);
}
