import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'job_details_page.dart'; // Import the JobDetailsPage

class RecommendationWidget extends StatefulWidget {
  @override
  _RecommendationWidgetState createState() => _RecommendationWidgetState();
}

class _RecommendationWidgetState extends State<RecommendationWidget> {
  late ScrollController _scrollController;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (_scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        double currentScroll = _scrollController.position.pixels;
        double nextScroll = currentScroll + 250;

        if (currentScroll == maxScroll) {
          _scrollController.jumpTo(0); // Jump back to the start without animation
        } else {
          _scrollController.animateTo(
            nextScroll,
            duration: Duration(seconds: 1),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('EmployerJobPost').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No job recommendations available.'));
        }

        return ListView(
          scrollDirection: Axis.horizontal,
          controller: _scrollController,
          children: snapshot.data!.docs.map((doc) {
            var jobData = doc.data() as Map<String, dynamic>;

            // Handle skills and requirements fields
            List<dynamic> skills = [];
            if (jobData['skills'] is String) {
              skills = [jobData['skills']];
            } else if (jobData['skills'] is List) {
              skills = jobData['skills'];
            }

            List<dynamic> requirements = [];
            if (jobData['requirements'] is String) {
              requirements = [jobData['requirements']];
            } else if (jobData['requirements'] is List) {
              requirements = jobData['requirements'];
            }

            return GestureDetector(
              onTap: () {
                // Navigate to JobDetailsPage when the card is tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JobDetailsPage(
                      jobTitle: jobData['jobTitle'] ?? 'N/A',
                      company: jobData['company'] ?? 'N/A',
                      employerId: jobData['employerId'] ?? 'N/A',
                      address: jobData['address'] ?? 'N/A',
                      salaryRange: jobData['salaryRange'] ?? 'N/A',
                      salaryPaymentStyle: jobData['salaryPaymentStyle'] ?? 'N/A',
                      expiry: jobData['expiry'] ?? 'N/A',
                      yearExperience: jobData['yearExperience']?.toString() ?? 'N/A',
                      aboutRole: jobData['aboutRole'] ?? 'N/A',
                      skills: skills,
                      requirements: requirements,
                      status: jobData['status'] ?? 'N/A',
                      category: jobData['category'] ?? 'N/A',
                      jobType: jobData['jobType'] ?? 'N/A',
                      jobSchedule: jobData['jobSchedule'] ?? 'N/A',
                      companyLogoUrl: jobData['companyLogoUrl'] ?? '',
                    ),
                  ),
                );
              },
              child: JobCard(
                jobTitle: jobData['jobTitle'] ?? 'N/A',
                company: jobData['company'] ?? 'N/A',
                employerId: jobData['employerId'] ?? 'N/A',
                address: jobData['address'] ?? 'N/A',
                salaryRange: jobData['salaryRange'] ?? 'N/A',
                salaryPaymentStyle: jobData['salaryPaymentStyle'] ?? 'N/A',
                expiry: jobData['expiry'] ?? 'N/A',
                yearExperience: jobData['yearExperience']?.toString() ?? 'N/A',
                aboutRole: jobData['aboutRole'] ?? 'N/A',
                skills: skills,
                requirements: requirements,
                status: jobData['status'] ?? 'N/A',
                category: jobData['category'] ?? 'N/A',
                jobType: jobData['jobType'] ?? 'N/A',
                jobSchedule: jobData['jobSchedule'] ?? 'N/A',
                companyLogoUrl: jobData['companyLogoUrl'] ?? '',
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class JobCard extends StatelessWidget {
  final String jobTitle;
  final String company;
  final String employerId;
  final String address;
  final String salaryRange;
  final String salaryPaymentStyle;
  final String expiry;
  final String yearExperience;
  final String aboutRole;
  final List<dynamic> skills;
  final List<dynamic> requirements;
  final String status;
  final String category;
  final String jobType;
  final String jobSchedule;
  final String companyLogoUrl;

  JobCard({
    required this.jobTitle,
    required this.company,
    required this.employerId,
    required this.address,
    required this.salaryRange,
    required this.salaryPaymentStyle,
    required this.expiry,
    required this.yearExperience,
    required this.aboutRole,
    required this.skills,
    required this.requirements,
    required this.status,
    required this.category,
    required this.jobType,
    required this.jobSchedule,
    required this.companyLogoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      margin: EdgeInsets.only(right: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (companyLogoUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.network(
                    companyLogoUrl,
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 5),
                    Text(
                      jobTitle,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '$jobType | $jobSchedule | $yearExperience years exp.',
            style: TextStyle(
              color: Colors.grey[700],
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Salary Payment: $salaryPaymentStyle',
            style: TextStyle(color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Expiry: $expiry',
            style: TextStyle(color: Colors.red[400]),
          ),
          Spacer(),
          Text(
            '$salaryRange/year',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
