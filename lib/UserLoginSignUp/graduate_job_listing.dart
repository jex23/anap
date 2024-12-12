import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'graduate_job_search_delegate.dart'; // Import the new file
import 'graduate_job_details.dart'; // Ensure this import path is correct

class GraduateJobListing extends StatefulWidget {
  final String category;

  GraduateJobListing({required this.category});

  @override
  _GraduateJobListingState createState() => _GraduateJobListingState();
}

class _GraduateJobListingState extends State<GraduateJobListing> {
  final TextEditingController _searchController = TextEditingController();

  void _handleSearch(String query) {
    // Trigger search using the JobSearchDelegate
    if (query.isNotEmpty) {
      showSearch(
        context: context,
        delegate: JobSearchDelegate(category: widget.category),
        query: query, // Pass the query to the search delegate
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
              _handleSearch(_searchController.text); // Trigger search manually
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Redesigned Search Bar
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
                controller: _searchController, // Link controller to search bar
                decoration: InputDecoration(
                  hintText: 'Search job, company etc...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                onSubmitted: _handleSearch, // Trigger search when pressing enter
              ),
            ),
            SizedBox(height: 20),

            // Job Listings
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('EmployerJobPost')
                    .where('status', isEqualTo: 'Graduate')
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
    String imageUrl = job['companyLogoUrl'] ?? ''; // Fetch the image URL

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    height: 80,
                    width: 100,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    height: 180,
                    width: double.infinity,
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
                ]),
                SizedBox(height: 5),
                Text(
                  job['salaryRange'] ?? 'No salary range',
                  style: TextStyle(color: Colors.redAccent),
                ),
                SizedBox(height: 10),
                Text(
                  job['address'] ?? 'No address',
                  style: TextStyle(color: Colors.grey[600]),
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
                      builder: (context) => GraduateJobDetails(job: job),
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
