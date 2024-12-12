import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import intl for date formatting
import 'menu_drawer.dart'; // Import MenuDrawer if you want to keep the drawer menu

class ChatPage extends StatefulWidget {
  final User user;
  final String employerId;
  final String jobTitle; // Add jobTitle
  final String company;  // Add company
  final String companyLogoUrl;  // Add company

  ChatPage({
    required this.user,
    required this.employerId,
    required this.jobTitle,
    required this.company,
    required this.companyLogoUrl,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String _employerName = '';
  String _employerPhotoUrl = ''; // Add variable to hold employer's photo URL

  @override
  void initState() {
    super.initState();
    _fetchEmployerDetails(); // Fetch employer's name and photo
  }

  // Fetch the employer's details from Firestore based on employerId
  Future<void> _fetchEmployerDetails() async {
    DocumentSnapshot employerSnapshot = await _firestore.collection('Employer').doc(widget.employerId).get();
    if (employerSnapshot.exists) {
      Map<String, dynamic> employerData = employerSnapshot.data() as Map<String, dynamic>;
      setState(() {
        _employerName = '${employerData['firstName'] ?? ''} ${employerData['lastName'] ?? ''}'.trim();
        _employerPhotoUrl = employerData['photoUrl'] ?? ''; // Get the employer's photo URL
      });
    }
  }

  // Format timestamp to readable date
  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final formatter = DateFormat('MMM d, yyyy – h:mm a'); // 12-hour format with AM/PM
    return formatter.format(date);
  }

  // Send message to Firestore with conversation ID and subcollection structure
  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      try {
        String conversationId = widget.jobTitle + widget.company + widget.employerId + _auth.currentUser!.uid;

        // Reference to the conversation document
        DocumentReference conversationDoc = _firestore.collection('conversations').doc(conversationId);

        // Check if the conversation document exists
        DocumentSnapshot conversationSnapshot = await conversationDoc.get();

        if (!conversationSnapshot.exists) {
          // Create the main conversation document
          await conversationDoc.set({
            'jobTitle': widget.jobTitle,
            'company': widget.company,
            'employerId': widget.employerId,
            'companyLogoUrl': widget.companyLogoUrl,
            'applicantsId': _auth.currentUser!.uid,
            'createdAt': Timestamp.now(),
          });
        }

        // Add message to the 'messages' subcollection
        await conversationDoc.collection('messages').add({
          'text': _messageController.text,
          'senderId': _auth.currentUser!.uid,
          'senderType': 'user',
          'createdAt': Timestamp.now(),
        });

        _messageController.clear();
      } catch (e) {
        print('Error sending message: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[300],
        elevation: 0,
        title: FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('Applicants').doc(widget.user.uid).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Loading...');
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text('User');
            }

            var userData = snapshot.data!.data() as Map<String, dynamic>;
            String fullName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
            String photoUrl = userData['photoUrl'] ?? '';

            return Row(
              children: [
                if (photoUrl.isNotEmpty)
                  CircleAvatar(
                    backgroundImage: NetworkImage(photoUrl),
                  ),
                SizedBox(width: 10),
                Text(
                  'Hello, $fullName',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            );
          },
        ),

      ),
      drawer: MenuDrawer(user: widget.user),
      body: Column(
        children: <Widget>[
          // Add a bar showing the employer's photo and name
          if (_employerName.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      if (_employerPhotoUrl.isNotEmpty)
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(_employerPhotoUrl),
                        ),
                      SizedBox(width: 10),
                      Text(
                        _employerName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 10),
                  Text('Application', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(widget.jobTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(widget.company, style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('conversations')
                  .doc(widget.jobTitle + widget.company + widget.employerId + _auth.currentUser!.uid)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No messages yet.'));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var message = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    bool isUserMessage = message['senderId'] == _auth.currentUser?.uid;

                    return Row(
                      mainAxisAlignment: isUserMessage
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!isUserMessage && _employerPhotoUrl.isNotEmpty)
                          CircleAvatar(
                            backgroundImage: NetworkImage(_employerPhotoUrl),
                          ),
                        if (isUserMessage && widget.user.photoURL != null)
                          CircleAvatar(
                            backgroundImage: NetworkImage(widget.user.photoURL!),
                          ),
                        SizedBox(width: 10),
                        Container(
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.symmetric(vertical: 5),
                          constraints: BoxConstraints(maxWidth: 250),
                          decoration: BoxDecoration(
                            color: isUserMessage ? Colors.blue[300] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: isUserMessage
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                message['text'] ?? '',
                                style: TextStyle(
                                  color: isUserMessage ? Colors.white : Colors.black,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                _formatTimestamp(message['createdAt'] as Timestamp),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isUserMessage ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isUserMessage) SizedBox(width: 10),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: 'Enter your message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
