import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting

class EmployerCommentsScreen extends StatefulWidget {
  final String postId;

  EmployerCommentsScreen({required this.postId});

  @override
  _EmployerCommentsScreenState createState() => _EmployerCommentsScreenState();
}

class _EmployerCommentsScreenState extends State<EmployerCommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  String? fullName;
  String? photoUrl;
  String? replyingToCommentId;
  final Map<String, bool> _showMoreReplies = {}; // Track reply visibility

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Function to fetch user data
  Future<void> _fetchUserData() async {
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Employer').doc(user!.uid).get();
        if (userDoc.exists) {
          String firstName = userDoc['firstName'] ?? '';
          String lastName = userDoc['lastName'] ?? '';
          fullName = '$firstName $lastName';
          photoUrl = userDoc['photoUrl'] ?? 'https://via.placeholder.com/150';
          setState(() {}); // Refresh UI with fetched data
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  // Function to submit a comment or reply
  Future<void> _submitComment() async {
    if (_commentController.text.isEmpty) {
      return; // Do nothing if the text field is empty
    }

    try {
      String collectionPath = replyingToCommentId == null
          ? 'comments'
          : 'comments/$replyingToCommentId/replies';

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection(collectionPath)
          .add({
        'userId': user?.uid,
        'userName': fullName,
        'photoUrl': photoUrl,
        'content': _commentController.text,
        'createdAt': Timestamp.now(),
      });

      _commentController.clear();
      replyingToCommentId = null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting comment: $e')),
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _formatDate(Timestamp timestamp) {
    return DateFormat('hh:mm dd/MM/yyyy').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No comments yet.'));
                }

                var comments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    var comment = comments[index];
                    _showMoreReplies.putIfAbsent(comment.id, () => false);

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    comment['photoUrl'] ?? 'https://via.placeholder.com/150',
                                  ),
                                  radius: 20,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(comment['userName'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold)),
                                      SizedBox(height: 5),
                                      Text(comment['content']),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDate(comment['createdAt']),
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        replyingToCommentId = comment.id;
                                        _commentController.text = ''; // Clear the text field when replying
                                      });
                                    },
                                    child: Text('Reply', style: TextStyle(color: Colors.blue)),
                                  ),
                                ],
                              ),
                            ),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(widget.postId)
                                  .collection('comments')
                                  .doc(comment.id)
                                  .collection('replies')
                                  .orderBy('createdAt', descending: false)
                                  .snapshots(),
                              builder: (context, replySnapshot) {
                                if (replySnapshot.connectionState == ConnectionState.waiting) {
                                  return Padding(
                                    padding: EdgeInsets.only(left: 60),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }

                                var replies = replySnapshot.data?.docs ?? [];

                                if (replies.isEmpty) {
                                  return SizedBox.shrink();
                                }

                                return Column(
                                  children: [
                                    // Show only the first reply
                                    if (replies.isNotEmpty && !_showMoreReplies[comment.id]!) ...[
                                      Card(
                                        margin: EdgeInsets.only(top: 8, left: 60),
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundImage: NetworkImage(
                                                  replies[0]['photoUrl'] ?? 'https://via.placeholder.com/150',
                                                ),
                                                radius: 15,
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(replies[0]['userName'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold)),
                                                    SizedBox(height: 5),
                                                    Text(
                                                      replies[0]['content'],
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                _formatDate(replies[0]['createdAt']),
                                                style: TextStyle(color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _showMoreReplies[comment.id] = true;
                                          });
                                        },
                                        child: Text('View ${replies.length} more replies'),
                                      ),
                                    ],
                                    // Show all replies if 'View more replies' is clicked
                                    if (_showMoreReplies[comment.id]!) ...[
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: replies.length,
                                        itemBuilder: (context, replyIndex) {
                                          var reply = replies[replyIndex];
                                          return Card(
                                            margin: EdgeInsets.only(top: 8, left: 60),
                                            child: Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      CircleAvatar(
                                                        backgroundImage: NetworkImage(
                                                          reply['photoUrl'] ?? 'https://via.placeholder.com/150',
                                                        ),
                                                        radius: 15,
                                                      ),
                                                      SizedBox(width: 10),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: [
                                                                Text(
                                                                  reply['userName'] ?? 'Unknown',
                                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                                ),
                                                                Text(
                                                                  _formatDate(reply['createdAt']),
                                                                  style: TextStyle(color: Colors.grey),
                                                                ),
                                                              ],
                                                            ),
                                                            SizedBox(height: 5),
                                                            Text(reply['content']),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      labelText: replyingToCommentId != null
                          ? 'Replying to comment...'
                          : 'Write a comment...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _submitComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
