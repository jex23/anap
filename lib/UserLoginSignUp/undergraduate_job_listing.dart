import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'undergraduate_job_search_delegate.dart'; // Import the new file
import 'undergraduate_job_details.dart'; // Ensure this import path is correct

class UndergraduateJobListing extends StatefulWidget {
  final String category;

  UndergraduateJobListing({required this.category});

  @override
  _UndergraduateJobListingState createState() => _UndergraduateJobListingState();
}

class _UndergraduateJobListingState extends State<UndergraduateJobListing> {
  final TextEditingController _searchController = TextEditingController();

  void _handleSearch(String query) {
    if (query.isNotEmpty) {
      showSearch(
        context: context,
        delegate: UndergraduateJobSearchDelegate(category: widget.category),
        query: query,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[300],
        elevation: 0,
        title: Center(child: Text(widget.category)),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
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
                  hintText: 'Search job, company, etc...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                onSubmitted: _handleSearch,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('EmployerJobPost')
                    .where('status', isEqualTo: 'Undergraduate')
                    .where('category', isEqualTo: widget.category)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No jobs found in this category'));
                  }

                  final jobDocs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: jobDocs.length,
                    itemBuilder: (context, index) {
                      final job = jobDocs[index].data() as Map<String, dynamic>;
                      return _buildJobCard(job);
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

  Widget _buildJobCard(Map<String, dynamic> job) {
    String imageUrl = job['companyLogoUrl'] ?? '';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  height: 80,
                  width: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 80,
                      width: 100,
                      color: Colors.grey[200],
                      child: Center(child: Text('No Image Available')),
                    );
                  },
                )
                    : Container(
                  height: 80,
                  width: 100,
                  color: Colors.grey[200],
                  child: Center(child: Text('No Image Available')),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Text(
              job['salaryRange'] ?? 'No salary range',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              job['address'] ?? 'No address',
              style: TextStyle(color: Colors.grey[600]),
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
                      builder: (context) => UndergraduateJobDetails(job: job),
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
