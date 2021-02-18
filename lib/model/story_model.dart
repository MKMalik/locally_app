import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final Timestamp createdAt;
  final String senderName;
  final String story;
  final String type;

  StoryModel({this.createdAt, this.senderName, this.story, this.type});
}
