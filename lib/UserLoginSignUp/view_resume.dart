import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewResumeScreen extends StatelessWidget {
  final String userId;

  ViewResumeScreen({required this.userId});

  Future<String?> _getResumeUrl() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('Applicants_Resume').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['resumeUrl'] as String?;
      }
    } catch (e) {
      print('Error fetching resume URL: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('View Resume')),
      body: FutureBuilder<String?>(
        future: _getResumeUrl(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text('Error loading resume or no resume available'));
          }

          final resumeUrl = snapshot.data!;
          return resumeUrl.isEmpty
              ? Center(child: Text('No resume uploaded'))
              : SfPdfViewer.network(resumeUrl);
        },
      ),
    );
  }
}
