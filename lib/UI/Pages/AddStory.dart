import 'dart:io';

import 'package:LocalStory/UI/Pages/SettingPage.dart';
import 'package:LocalStory/constant.dart';
import 'package:LocalStory/model/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddStory extends StatefulWidget {
  @override
  _AddStoryState createState() => _AddStoryState();
}

class _AddStoryState extends State<AddStory> {
  String type = 'Text';
  ScrollController _scrollController = ScrollController();
  TextEditingController _storyTextController = TextEditingController();
  FocusNode _focusNode = FocusNode();

  File _image;

  loadImage() {
    ImagePicker.pickImage(
            source: ImageSource.gallery, imageQuality: 70, maxHeight: 720)
        .then((image) {
      setState(() {
        _image = image;
      });
    });
  }

  bool _isButtonDisabled() {
    bool res;
    if (type == 'Text') {
      res = _storyTextController.value.text.trim().isEmpty;
    } else if (type == 'Image') {
      res = _image == null;
    }

    return res;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Widget uploadRespose({Size size, String msg, Widget widget}) {
    showDialog(
      barrierDismissible: false,
      context: context,
      child: AlertDialog(
        backgroundColor: Colors.transparent,
        content: Container(
          width: size.width * 0.2,
          height: size.height * 0.1,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size.width * 0.08)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              widget,
              Text(
                '$msg',
                style:
                    TextStyle(color: Colors.white, fontSize: size.width * 0.07),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    List<String> options = ['Text', 'Image'];

    final _userProvider = Provider.of<LoginProvider>(context);
    final _currentUser = FirebaseAuth.instance.currentUser;

    addTextStory(String storyText) {
      _userProvider
          .addTextStory(postText: storyText.trim(), userId: _currentUser.uid)
          .then((res) {
        if (res) {
          // add response for user on story upload success
          Navigator.of(context).pop(); // to pop the dialog
          Navigator.of(context).pop(); // to pop the current page
        } else {
          // add response for user on story upload failed
          print('story sending failed');
          uploadRespose(
              msg: 'Failed',
              size: size,
              widget: Icon(
                Icons.cancel_outlined,
                color: Colors.red,
              ));
        }
      });
    }

    addImageStory(imagePath) async {
      String imageLink;
      String storyId = Uuid().v4();
      var storageReference = FirebaseStorage.instance.ref();
      var ref = storageReference.child(_currentUser.uid).child(storyId);
      File _imageFile = File(_image.path);

      await ref.putFile(_imageFile);
      imageLink = await ref.getDownloadURL();
      print(imageLink);

      _userProvider
          .addImageStory(
              imageLink: imageLink, userId: _currentUser.uid, storyId: storyId)
          .then((res) {
        if (res) {
          Navigator.of(context).pop(); // to pop the dialog
          Navigator.of(context).pop(); // to pop the current page
        } else {
          Navigator.of(context).pop();
          print('story sending failed');
          uploadRespose(
              msg: 'Failed',
              size: size,
              widget: Icon(
                Icons.cancel_outlined,
                color: Colors.red,
              ));
        }
      });
    }

    void addStory() {
      showDialog(
        barrierDismissible: false,
        context: context,
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          content: Container(
            width: size.width * 0.2,
            height: size.height * 0.1,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size.width * 0.08)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                Text(
                  'Uploading...',
                  style: TextStyle(
                      color: Colors.white, fontSize: size.width * 0.07),
                ),
              ],
            ),
          ),
        ),
      );
      _focusNode.unfocus();
      if (type == 'Text') {
        addTextStory(_storyTextController.value.text);
      } else if (type == 'Image') {
        addImageStory(_image.path);
      }
    }

    if (_focusNode.hasFocus)
      _scrollController.animateTo(size.height * 0.22,
          duration: Duration(milliseconds: 500), curve: Curves.ease);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Container(
          height: size.height,
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
                child: Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Add Story',
                              style: GoogleFonts.coda(
                                  textStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: size.width * 0.08)),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.settings,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (BuildContext context) {
                                  return SettingPage();
                                }));
                              },
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        child: SizedBox(),
                      ),
                      // drop down menu to select type of story (Text, Photo)
                      dropDownMenu(options),
                      SizedBox(
                        height: size.height * 0.04,
                      ),

                      type == 'Text'
                          ? textStoryWidget(size)
                          : imageStoryWidget(size),

                      SizedBox(
                        height: size.height * 0.05,
                      ),

                      // child: InkWell(
                      //   borderRadius: BorderRadius.circular(50),
                      //   onTap: () {
                      //     // postTextStory();
                      //   },
                      // ),

                      // RaisedButton(
                      //   disabledColor: Colors.grey,
                      //   child: Padding(
                      //     padding: const EdgeInsets.symmetric(
                      //         horizontal: 20, vertical: 10),
                      //     child: Text(
                      //       'Post',
                      //       style: TextStyle(
                      //           color: _isButtonDisabled()
                      //               ? Colors.white70
                      //               : backgroundColor,
                      //           fontSize: size.width * 0.05,
                      //           fontWeight: FontWeight.bold),
                      //     ),
                      //   ),
                      //   onPressed: _isButtonDisabled() ? null : addStory,
                      // ),

                      Expanded(
                        child: SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isButtonDisabled() ? null : addStory,
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            'Post',
            style: TextStyle(
                color: _isButtonDisabled() ? Colors.white70 : backgroundColor,
                fontSize: size.width * 0.05,
                fontWeight: FontWeight.bold),
          ),
        ),
        disabledElevation: 0,
        elevation: 5,
        backgroundColor: _isButtonDisabled() ? Colors.grey : Colors.white,
      ),
    );
  }

  Widget textStoryWidget(Size size) {
    return Container(
      width: size.width *
          0.8 *
          0.9, // * 0.9 is to get the same size as on the story page
      height: size.height * 0.6,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          onChanged: (value) {
            setState(() {});
          },
          controller: _storyTextController,
          focusNode: _focusNode,
          maxLines: 20,
          maxLength: 300,
          decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Share your thoughs...',
              hintStyle: TextStyle(
                  color: backgroundColor.withOpacity(0.6),
                  fontWeight: FontWeight.bold)
              // labelText: 'Share your thoughs...',
              ),
          style: TextStyle(fontSize: size.width * 0.05),
        ),
      ),
    );
  }

  Widget imageStoryWidget(Size size) {
    return GestureDetector(
      onTap: () {
        print('load image');
        loadImage();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: size.width *
              0.8 *
              0.9, // * 0.9 is to get the same size as on the story page
          height: size.height * 0.6,
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: GestureDetector(
            child: _image == null
                ? Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'Assets/camera.svg',
                        ),
                        SizedBox(
                          height: size.height * 0.04,
                        ),
                        Text(
                          'Tap to load image',
                          style: TextStyle(
                            color: backgroundColor,
                            fontWeight: FontWeight.bold,
                            fontSize: size.width * 0.05,
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage(_image.path), fit: BoxFit.cover)),
                  ),
          ),
        ),
      ),
    );
  }

  // drop down menu to select type of story (Text, Photo)
  Widget dropDownMenu(List<String> options) {
    return Center(
      child: DropdownButton(
        underline: SizedBox(),
        dropdownColor: backgroundColor,
        value: type,
        hint: Text('Story Type'), // Not necessary for Option 1
        onChanged: (newValue) {
          setState(() {
            type = newValue;
          });
        },
        items: options.map((option) {
          return DropdownMenuItem(
            child: Container(
              child: new Text(
                option,
                style: TextStyle(color: Colors.white),
              ),
            ),
            value: option,
            onTap: () {
              setState(() {
                type = option;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget textStroyWidget() {
    return Scaffold(
      body: Container(
          child: Center(
        child: Text('Add Text Story'),
      )),
    );
  }

  Widget photoStroyWidget() {
    return Scaffold(
      body: Container(
        child: Center(
          child: Text('Add photo story'),
        ),
      ),
    );
  }
}
