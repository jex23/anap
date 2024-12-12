import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'undergraduate_job_listing.dart'; // Import the UndergraduateJobListing page

class UndergraduateJobs extends StatelessWidget {
  // Fetch job data from Firestore where the status is "Undergraduate"
  Future<Map<String, int>> _fetchJobCounts() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('EmployerJobPost')
        .where('status', isEqualTo: 'Undergraduate')
        .get();

    // Initialize a map to store job counts by category
    Map<String, int> jobCounts = {
      'Public Market': 0,
      'SuperMarket': 0,
      'Food': 0,
      'Arts': 0,
      'Fabrication': 0,
      'Freelance': 0,
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
      case 'Public Market':
        return 'Vendor, Market Supervisor';
      case 'SuperMarket':
        return 'Manager, Cashier';
      case 'Food':
        return 'Chef, Food Vendor, Waiter';
      case 'Arts':
        return 'Painter, Sculptor, Graphic Designer';
      case 'Fabrication':
        return 'Welder, Machinist, Fabricator';
      case 'Freelance':
        return 'Freelance Writer, Web Developer, Graphic Designer';
      default:
        return 'N/A';
    }
  }

  // Helper method to return icons for each category
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Public Market':
        return Icons.store;
      case 'SuperMarket':
        return Icons.shopping_cart;
      case 'Food':
        return Icons.restaurant;
      case 'Arts':
        return Icons.palette;
      case 'Fabrication':
        return Icons.build;
      case 'Freelance':
        return Icons.laptop_mac;
      default:
        return Icons.work; // Default icon
    }
  }

  Widget _buildCategoryListItem(BuildContext context, String category, String count, String details) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UndergraduateJobListing(category: category),
          ),
        );
      },
      child: Container(
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
                SizedBox(width: 8), // Add some spacing between the icon and text
                Icon(
                  _getCategoryIcon(category),
                  color: Colors.redAccent, // AccentRed color
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
              child: Text("See more...", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
