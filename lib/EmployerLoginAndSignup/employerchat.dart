import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'employee_menu_drawer.dart'; // Import employee menu drawer for navigation

class EmployerChatPage extends StatefulWidget {
  final User user;
  final String applicantsId;
  final String jobTitle;
  final String company;
  final String companyLogoUrl;
  final String applicantFullName;

  EmployerChatPage({
    required this.user,
    required this.applicantsId,
    required this.jobTitle,
    required this.company,
    required this.companyLogoUrl,
    required this.applicantFullName,
  });

  @override
  _EmployerChatPageState createState() => _EmployerChatPageState();
}

class _EmployerChatPageState extends State<EmployerChatPage> {
  final _messageController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  String _applicantName = '';
  String _applicantPhotoUrl = ''; // Add variable for applicant's photo URL

  @override
  void initState() {
    super.initState();
    _fetchApplicantDetails(); // Fetch the applicant's details on initialization
  }

  // Fetch the applicant's details from Firestore
  Future<void> _fetchApplicantDetails() async {
    DocumentSnapshot applicantSnapshot = await _firestore
        .collection('Applicants')
        .doc(widget.applicantsId)
        .get();
    if (applicantSnapshot.exists) {
      Map<String, dynamic> applicantData = applicantSnapshot.data() as Map<String, dynamic>;
      setState(() {
        _applicantName = '${applicantData['firstName'] ?? ''} ${applicantData['lastName'] ?? ''}'.trim();
        _applicantPhotoUrl = applicantData['photoUrl'] ?? 'https://via.placeholder.com/150'; // Default photo if not available
      });
    }
  }

  // Format the timestamp to a readable date format
  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final formatter = DateFormat('MMM d, yyyy – h:mm a'); // Formatting to 12-hour format
    return formatter.format(date);
  }

  // Send a message to Firestore
  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      try {
        String conversationId = widget.jobTitle + widget.company + widget.user.uid + widget.applicantsId ;

        DocumentReference conversationDoc = _firestore.collection('conversations').doc(conversationId);

        // Check if conversation exists, if not create one
        DocumentSnapshot conversationSnapshot = await conversationDoc.get();
        if (!conversationSnapshot.exists) {
          await conversationDoc.set({
            'jobTitle': widget.jobTitle,
            'company': widget.company,
            'employerId': widget.user.uid,
            'applicantsId': widget.applicantsId,
            'companyLogoUrl': widget.companyLogoUrl,
            'createdAt': Timestamp.now(),
          });
        }

        // Add message to the conversation's messages subcollection
        await conversationDoc.collection('messages').add({
          'text': _messageController.text,
          'senderId': widget.user.uid,
          'senderType': 'employer',
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
        title: Row(
          children: [
            if (_applicantPhotoUrl.isNotEmpty)
              CircleAvatar(
                backgroundImage: NetworkImage(_applicantPhotoUrl),
              ),
            SizedBox(width: 10),
            Text(
              _applicantName.isNotEmpty ? 'Chat with $_applicantName' : 'Chat',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ],
        ),
      ),
      drawer: EmployeeMenuDrawer(user: widget.user), // Drawer for navigation
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    if (widget.companyLogoUrl.isNotEmpty)
                      CircleAvatar(
                        backgroundImage: NetworkImage(widget.companyLogoUrl),
                        radius: 24,
                      ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.jobTitle,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(widget.company),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('conversations')
                  .doc(widget.jobTitle + widget.company + widget.user.uid  + widget.applicantsId)
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No messages yet.'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var message = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    bool isEmployerMessage = message['senderId'] == widget.user.uid;

                    return Row(
                      mainAxisAlignment: isEmployerMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        if (!isEmployerMessage)
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: _applicantPhotoUrl.isNotEmpty ? NetworkImage(_applicantPhotoUrl) : null,
                          ),
                        SizedBox(width: 10),
                        Container(
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.symmetric(vertical: 5),
                          constraints: BoxConstraints(maxWidth: 250),
                          decoration: BoxDecoration(
                            color: isEmployerMessage ? Colors.red[300] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment:
                            isEmployerMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                message['text'] ?? '',
                                style: TextStyle(
                                  color: isEmployerMessage ? Colors.white : Colors.black,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                _formatTimestamp(message['createdAt'] as Timestamp),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isEmployerMessage ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isEmployerMessage) SizedBox(width: 10),
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
