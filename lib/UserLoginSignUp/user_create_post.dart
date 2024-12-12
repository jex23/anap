import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class UserCreatePostScreen extends StatefulWidget {
  final User user;

  UserCreatePostScreen({required this.user});

  @override
  _UserCreatePostScreenState createState() => _UserCreatePostScreenState();
}

class _UserCreatePostScreenState extends State<UserCreatePostScreen> {
  TextEditingController _postController = TextEditingController();
  bool _isLoading = false;
  List<File> _selectedImages = [];
  String? _selectedFeeling;
  String _userName = 'Unknown User';
  String _userPhotoUrl = 'https://via.placeholder.com/150';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Applicants')
          .doc(widget.user.uid)
          .get();

      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _userName =
              '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
          _userPhotoUrl = userData['photoUrl'] ?? _userPhotoUrl;
        });
      }
    } catch (error) {
      print("Error fetching user data: $error");
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker _picker = ImagePicker();
    final List<XFile>? images = await _picker.pickMultiImage();

    if (images != null) {
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  Future<List<String?>> _uploadImages() async {
    List<String?> imageUrls = [];
    for (File image in _selectedImages) {
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('post_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = storageRef.putFile(image);
        final snapshot = await uploadTask.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      } catch (error) {
        print("Error uploading image: $error");
        imageUrls.add(null);
      }
    }
    return imageUrls;
  }

  Future<void> _createPost() async {
    if (_postController.text.isEmpty &&
        _selectedImages.isEmpty &&
        _selectedFeeling == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post content, images, or feeling is required'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<String?> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages();
      }

      await FirebaseFirestore.instance.collection('posts').add({
        'content': _postController.text,
        'createdAt': Timestamp.now(),
        'userId': widget.user.uid,
        'userName': _userName,
        'photoUrl': _userPhotoUrl,
        'feeling': _selectedFeeling,
        'images': imageUrls.where((url) => url != null).toList(),
        'status': "Pending",
      });

      // Show dialog to wait for admin approval
      _showApprovalDialog();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create post: $error'),
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showApprovalDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Post Submission'),
          content: Text('Wait for Admin Approval for the Post.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pop(context); // Optionally close the post creation screen
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _removeImage(File image) {
    setState(() {
      _selectedImages.remove(image);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Create Post',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
              'Post',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red[300]!, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(_userPhotoUrl),
                  ),
                  SizedBox(width: 10),
                  Text(
                    _userName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  controller: _postController,
                  maxLines: 5,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "What's on your mind?",
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(15),
                  ),
                ),
              ),
              SizedBox(height: 20),
              if (_selectedImages.isNotEmpty)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _selectedImages.map((image) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            image,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: -10,
                          right: -10,
                          child: IconButton(
                            icon: Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _removeImage(image),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: Icon(Icons.photo, color: Colors.white),
                label: Text('Add Photos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}