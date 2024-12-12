import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'employerchat.dart'; // Import the chat screen

class SearchApplicants extends StatefulWidget {
  final User? user;

  SearchApplicants({this.user});

  @override
  _SearchApplicantsState createState() => _SearchApplicantsState();
}

class _SearchApplicantsState extends State<SearchApplicants> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  void _searchApplicants() async {
    setState(() {
      _isLoading = true;
      _searchResults.clear();
    });

    try {
      String searchTerm = _searchController.text.trim().toLowerCase();

      // Query the Applicants_Resume collection
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Applicants_Resume')
          .get();

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> resumeData = doc.data() as Map<String, dynamic>;
        String id = doc.id;

        // Filter experiences that match the search term
        List<dynamic> experiences = resumeData['experience'] ?? [];
        List<Map<String, dynamic>> matchingExperiences = experiences
            .where((exp) =>
            (exp['experience']?.toString().toLowerCase() ?? '')
                .contains(searchTerm))
            .map((exp) => exp as Map<String, dynamic>)
            .toList();

        if (matchingExperiences.isNotEmpty) {
          // Fetch corresponding applicant details from Applicants collection
          DocumentSnapshot applicantDoc = await FirebaseFirestore.instance
              .collection('Applicants')
              .doc(id)
              .get();

          // Check if the document exists and handle missing fields
          if (applicantDoc.exists) {
            Map<String, dynamic>? applicantData =
            applicantDoc.data() as Map<String, dynamic>?;

            _searchResults.add({
              'resume': {'experience': matchingExperiences},
              'applicant': applicantData ?? {}, // Default to empty map
              'applicantId': id, // Pass the applicant ID for navigation
            });
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching applicants: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildExperienceDetails(dynamic experience) {
    if (experience is List && experience.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: experience.map<Widget>((exp) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '- Experience: ${exp['experience'] ?? 'N/A'}',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                '  Company: ${exp['company'] ?? 'N/A'}',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                '  Start Date: ${exp['startDate'] ?? 'N/A'}',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                '  End Date: ${exp['endDate'] ?? 'N/A'}',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                '  Years: ${exp['years'] ?? 'N/A'}',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
            ],
          );
        }).toList(),
      );
    } else {
      return Text('- No Matching Experience Found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search Applicants',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by Experience, Company, or Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchApplicants,
                  child: Icon(Icons.search, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Search Results
            _isLoading
                ? CircularProgressIndicator()
                : Expanded(
              child: _searchResults.isEmpty
                  ? Center(
                child: Text('No results found'),
              )
                  : ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  final resume = result['resume'];
                  final applicant = result['applicant'] ?? {};
                  final applicantId = result['applicantId'];

                  String status =
                      applicant['status'] ?? 'Unemployed';
                  String hiringCompany =
                      applicant['hiringCompany'] ?? 'None';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                            applicant['photoUrl'] ??
                                'https://via.placeholder.com/150',
                          ),
                        ),
                        title: Text(
                          '${applicant['firstName'] ?? 'Unknown'} ${applicant['lastName'] ?? ''}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Address: ${applicant['address'] ?? 'Unknown'}',
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 8),
                            _buildExperienceDetails(
                                resume['experience']),
                            SizedBox(height: 8),
                            Text(
                              'Status: $status',
                              style: TextStyle(fontSize: 14),
                            ),
                            if (status == 'Hired')
                              Text(
                                'Hired by: $hiringCompany',
                                style: TextStyle(fontSize: 14),
                              ),
                            if (status != 'Hired')
                              Text(
                                'Unemployed',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.message,
                              color: Colors.redAccent),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EmployerChatPage(
                                      user: widget.user!,
                                      applicantsId: applicantId,
                                      jobTitle: resume['experience']
                                          ?.first['experience'] ??
                                          'Unknown',
                                      company: resume['experience']
                                          ?.first['company'] ??
                                          'Unknown',
                                      companyLogoUrl: applicant[
                                      'photoUrl'] ??
                                          'https://via.placeholder.com/150',
                                      applicantFullName:
                                      '${applicant['firstName'] ?? ''} ${applicant['lastName'] ?? ''}',
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
