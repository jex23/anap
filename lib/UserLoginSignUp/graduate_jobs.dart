import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'graduate_job_listing.dart'; // Import the new graduate job listing page

class GraduateJobs extends StatelessWidget {
  // Fetch job data from Firestore where the status is "Graduate"
  Future<Map<String, int>> _fetchJobCounts() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('EmployerJobPost')
        .where('status', isEqualTo: 'Graduate')
        .get();

    // Initialize a map to store job counts by category
    Map<String, int> jobCounts = {
      'Finance': 0,
      'Supermarket': 0,
      'Healthcare': 0,
      'Arts': 0,
      'Dentist': 0,
      'Agriculture': 0,
      'Business': 0,
      'Hospitality': 0,
      'Computer': 0,
    };

    // Iterate through the snapshot and count jobs per category
    snapshot.docs.forEach((doc) {
      var jobData = doc.data() as Map<String, dynamic>;
      String category = jobData['category'] ?? 'N/A';

      // Increment the count for the respective category
      if (jobCounts.containsKey(category)) {
        jobCounts[category] = jobCounts[category]! + 1;
      }
    });

    return jobCounts;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _fetchJobCounts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return Center(child: Text('No jobs found'));
        }

        // Extract job counts from snapshot data
        Map<String, int> jobCounts = snapshot.data!;

        return ListView.builder(
          itemCount: jobCounts.length,
          itemBuilder: (context, index) {
            String category = jobCounts.keys.elementAt(index);
            int count = jobCounts[category]!;
            String details = _getJobDetailsByCategory(category);

            return _buildCategoryListItem(context, category, count.toString(), details);
          },
        );
      },
    );
  }

  // Helper method to return sample job details for each category
  String _getJobDetailsByCategory(String category) {
    switch (category) {
      case 'Finance':
        return 'Financial Analyst, Accountant';
      case 'Supermarket':
        return 'Manager, Cashier';
      case 'Healthcare':
        return 'Nurse, Doctor, Pharmacist';
      case 'Arts':
        return 'Graphic Designer, Animator';
      case 'Dentist':
        return 'Dentist, Dental Assistant';
      case 'Agriculture':
        return 'Farmer, Agronomist';
      case 'Business':
        return 'Business Analyst, Entrepreneur';
      case 'Hospitality':
        return 'Hotel Manager, Chef';
      case 'Computer':
        return 'Software Developer, System Administrator';
      default:
        return 'N/A';
    }
  }

  Widget _buildCategoryListItem(BuildContext context, String category, String count, String details) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
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
            children: [
              Text(category, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(width: 8), // Spacing between icon and category text
              Icon(
                _getCategoryIcon(category),
                color: Colors.redAccent, // AccentRed color for icons
              ),
              Spacer(),
              Text(count, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          SizedBox(height: 5),
          Text(details, style: TextStyle(color: Colors.grey[700])),
          SizedBox(height: 5),
          Align(
            alignment: Alignment.bottomRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GraduateJobListing(category: category),
                  ),
                );
              },
              child: Text("See more...", style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to return icons for each category
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Finance':
        return Icons.attach_money;
      case 'Supermarket':
        return Icons.shopping_cart;
      case 'Healthcare':
        return Icons.local_hospital;
      case 'Arts':
        return Icons.brush;
      case 'Dentist':
        return Icons.medical_services;
      case 'Agriculture':
        return Icons.agriculture;
      case 'Business':
        return Icons.business_center;
      case 'Hospitality':
        return Icons.hotel;
      case 'Computer':
        return Icons.computer;
      default:
        return Icons.work; // Default icon
    }
  }
}
