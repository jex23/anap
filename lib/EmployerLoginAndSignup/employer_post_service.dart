import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'employer_comments_screen.dart';

class EmployerPostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, String> feelingEmojis = {
    'Happy': '😊',
    'Sad': '😢',
    'Angry': '😡',
    'Excited': '😃',
    'Love': '❤️',
    'Blessed': '🙏',
  };

  Stream<QuerySnapshot> fetchPosts() {
    return _firestore
        .collection('posts')
        .where('status', isEqualTo: 'Accepted')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addReaction(
      String postId, String userId, String reaction) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('reactions')
        .doc(userId)
        .set({
      'reaction': reaction,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Widget buildPostList(BuildContext context, User? user) {
    return StreamBuilder<QuerySnapshot>(
      stream: fetchPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Error loading posts'));
        }

        var posts = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            var post = posts[index];
            var data = post.data() as Map<String, dynamic>;

            return PostCard(
              postId: post.id,
              content: data['content'] ?? '',
              userName: data['userName'] ?? 'Unknown',
              photoUrl: data['photoUrl'] ?? 'https://via.placeholder.com/150',
              createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
              feeling: data['feeling'] ?? '',
              emoji: feelingEmojis[data['feeling']] ?? '',
              creator: data.containsKey('creator') ? data['creator'] : 'Unknown',
              imageUrls: data['images'] ?? [],
              user: user,
              onReaction: addReaction,
              onCommentPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmployerCommentsScreen(postId: post.id),
                  ),
                );
              },
              firestore: _firestore,
            );
          },
        );
      },
    );
  }
}


  class PostCard extends StatelessWidget {
  final String postId;
  final String content;
  final String userName;
  final String photoUrl;
  final DateTime? createdAt;
  final String feeling;
  final String emoji;
  final List<dynamic> imageUrls;
  final String? creator; // Field for creator
  final User? user;
  final Function(String postId, String userId, String reaction) onReaction;
  final VoidCallback onCommentPressed;
  final FirebaseFirestore firestore;

  const PostCard({
    Key? key,
    required this.postId,
    required this.content,
    required this.userName,
    required this.photoUrl,
    this.createdAt,
    required this.feeling,
    required this.emoji,
    required this.imageUrls,
    required this.creator,
    required this.user,
    required this.onReaction,
    required this.onCommentPressed,
    required this.firestore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          if (imageUrls.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImageViewer(
                  imageUrls: imageUrls,
                  initialIndex: 0,
                ),
              ),
            );
          }
        },
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Background Image or Gradient
                imageUrls.isNotEmpty
                    ? Image.network(
                        imageUrls[0],
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 300,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFEF9A9A), Colors.black26],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),

                // User Info Overlay
                Positioned(
                  top: 15,
                  left: 15,
                  child: IntrinsicWidth(
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(photoUrl),
                            radius: 22.5,
                          ),
                          const SizedBox(width: 5),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if (createdAt != null)
                                Text(
                                  _formatDateTime(createdAt!),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              Text(
                                creator ?? "Unknown", // Display creator
                                style: TextStyle(
                                  color: creator == "Employer"
                                      ? Colors.red
                                      : (creator == "Applicant"
                                          ? Colors.blue
                                          : Colors
                                              .grey), // Conditional coloring
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Overlay Content (Post and Actions)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (content.isNotEmpty)
                        Text(
                          content,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (feeling.isNotEmpty)
                        Text(
                          'Feeling $feeling $emoji',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      const SizedBox(height: 20),
                      _buildActionRow(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  // Helper Method to Format Date
  String _formatDateTime(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }

  // Helper Method to Build Action Row
  Widget _buildActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => onReaction(postId, user!.uid, 'like'),
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('posts')
                .doc(postId)
                .collection('reactions')
                .snapshots(),
            builder: (context, snapshot) {
              int likesCount =
                  snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Row(
                children: [
                  const Icon(Icons.thumb_up_alt_outlined, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    '$likesCount',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              );
            },
          ),
        ),
        GestureDetector(
          onTap: onCommentPressed,
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('posts')
                .doc(postId)
                .collection('comments')
                .snapshots(),
            builder: (context, snapshot) {
              int commentsCount =
                  snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Row(
                children: [
                  const Icon(Icons.comment_outlined, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    '$commentsCount',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              );
            },
          ),
        ),
        GestureDetector(
          onTap: () {
            // Handle share
          },
          child: const Icon(Icons.share_outlined, color: Colors.white),
        ),
      ],
    );
  }
}

class ImageViewer extends StatefulWidget {
  final List<dynamic> imageUrls;
  final int initialIndex;

  const ImageViewer(
      {Key? key, required this.imageUrls, required this.initialIndex})
      : super(key: key);

  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Image Viewer',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Center(
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imageUrls.length, (index) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  height: 8,
                  width: _currentIndex == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index ? Colors.white : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
