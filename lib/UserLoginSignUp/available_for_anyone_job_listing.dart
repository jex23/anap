import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'available_for_anyone_job_details.dart'; // Import the job details page

class AvailableForAnyoneJobListing extends StatefulWidget {
  final String category;

  AvailableForAnyoneJobListing({required this.category});

  @override
  _AvailableForAnyoneJobListingState createState() =>
      _AvailableForAnyoneJobListingState();
}

class _AvailableForAnyoneJobListingState
    extends State<AvailableForAnyoneJobListing> {
  final TextEditingController _searchController = TextEditingController();

  void _handleSearch(String query) {
    if (query.isNotEmpty) {
      print('Searching for: $query');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[300],
        title: Text('${widget.category} Jobs', style: TextStyle(color: Colors.white)),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              _handleSearch(_searchController.text);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search job, company etc...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                onSubmitted: _handleSearch,
              ),
            ),
            SizedBox(height: 20),

            // Job Listings
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('EmployerJobPost')
                    .where('status', isEqualTo: 'Available to Anyone')
                    .where('category', isEqualTo: widget.category)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No jobs found in this category.'));
                  }

                  final jobDocs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: jobDocs.length,
                    itemBuilder: (context, index) {
                      final job = jobDocs[index].data() as Map<String, dynamic>;
                      return _buildJobCard(job, context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job, BuildContext context) {
    String imageUrl = job['companyLogoUrl'] ?? '';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  height: 80,
                  width: 100,
                  fit: BoxFit.cover,
                )
                    : Container(
                  height: 80,
                  width: 100,
                  color: Colors.grey[200],
                  child: Center(child: Text('No Image')),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['jobTitle'] ?? 'No title',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        job['company'] ?? 'No company',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Salary: ${job['salaryRange'] ?? 'Not specified'}',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                      SizedBox(height: 5),
                      Text(
                        job['address'] ?? 'No address',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AvailableForAnyoneJobDetails(
                        job: job,
                      ),
                    ),
                  );
                },
                child: Text(
                  "See more...",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
