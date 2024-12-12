import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'available_for_anyone_job_listing.dart';

class AvailableForAnyoneJobs extends StatelessWidget {
  // Fetch job data where status is "Available to Anyone"
  Future<Map<String, int>> _fetchJobCounts() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('EmployerJobPost')
        .where('status', isEqualTo: 'Available to Anyone')
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
      'Public Market': 0,
      'Food': 0,
      'Fabrication': 0,
      'Freelance': 0,
    };

    // Count jobs for each category
    for (var doc in snapshot.docs) {
      var jobData = doc.data() as Map<String, dynamic>;
      String category = jobData['category'] ?? 'Uncategorized';

      if (jobCounts.containsKey(category)) {
        jobCounts[category] = jobCounts[category]! + 1;
      }
    }

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

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No jobs available.'));
        }

        final jobCounts = snapshot.data!;

        return ListView.builder(
          itemCount: jobCounts.length,
          itemBuilder: (context, index) {
            String category = jobCounts.keys.elementAt(index);
            int count = jobCounts[category]!;
            String details = _getCategoryDetails(category);

            return _buildCategoryCard(context, category, count, details);
          },
        );
      },
    );
  }

  // Helper to fetch details for each category
  String _getCategoryDetails(String category) {
    switch (category) {
      case 'Finance':
        return 'Accountant, Financial Analyst';
      case 'Supermarket':
        return 'Manager, Cashier';
      case 'Healthcare':
        return 'Nurse, Doctor';
      case 'Arts':
        return 'Graphic Designer, Painter';
      case 'Dentist':
        return 'Dental Assistant, Hygienist';
      case 'Agriculture':
        return 'Farmer, Agricultural Technician';
      case 'Business':
        return 'Manager, Consultant';
      case 'Hospitality':
        return 'Hotel Staff, Event Manager';
      case 'Computer':
        return 'IT Specialist, Software Developer';
      case 'Public Market':
        return 'Vendor, Market Supervisor';
      case 'Food':
        return 'Chef, Food Vendor, Waiter';
      case 'Fabrication':
        return 'Welder, Fabricator';
      case 'Freelance':
        return 'Freelancer, Remote Worker';
      default:
        return 'Various roles available';
    }
  }

  // Helper to build each category card
  Widget _buildCategoryCard(BuildContext context, String category, int count, String details) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    category,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    _getCategoryIcon(category),
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                details,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AvailableForAnyoneJobListing(category: category),
                    ),
                  );
                },
                child: Text(
                  "See more...",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper to fetch category icons
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Finance':
        return Icons.attach_money;
      case 'Supermarket':
        return Icons.shopping_cart;
      case 'Healthcare':
        return Icons.health_and_safety;
      case 'Arts':
        return Icons.brush;
      case 'Dentist':
        return Icons.medical_services;
      case 'Agriculture':
        return Icons.eco;
      case 'Business':
        return Icons.business;
      case 'Hospitality':
        return Icons.hotel;
      case 'Computer':
        return Icons.computer;
      case 'Public Market':
        return Icons.storefront;
      case 'Food':
        return Icons.restaurant;
      case 'Fabrication':
        return Icons.build;
      case 'Freelance':
        return Icons.laptop_mac;
      default:
        return Icons.work;
    }
  }
}
