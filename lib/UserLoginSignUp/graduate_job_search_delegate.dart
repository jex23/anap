import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'graduate_job_details.dart'; // Import the job details page

class JobSearchDelegate extends SearchDelegate {
  final String category;

  JobSearchDelegate({required this.category});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
      IconButton(
        icon: Icon(Icons.search),
        onPressed: () {
          showResults(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final jobStream = query.isEmpty
        ? FirebaseFirestore.instance
        .collection('EmployerJobPost')
        .where('status', isEqualTo: 'Graduate')
        .where('category', isEqualTo: category)
        .snapshots()
        : FirebaseFirestore.instance
        .collection('EmployerJobPost')
        .where('status', isEqualTo: 'Graduate')
        .where('category', isEqualTo: category)
        .where('jobTitle', isGreaterThanOrEqualTo: query)
        .where('jobTitle', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots();

    final companyStream = query.isNotEmpty
        ? FirebaseFirestore.instance
        .collection('EmployerJobPost')
        .where('status', isEqualTo: 'Graduate')
        .where('category', isEqualTo: category)
        .where('company', isGreaterThanOrEqualTo: query)
        .where('company', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots()
        : null;

    return StreamBuilder<QuerySnapshot>(
      stream: jobStream,
      builder: (context, jobSnapshot) {
        if (jobSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final jobDocs = jobSnapshot.hasData ? jobSnapshot.data!.docs : <DocumentSnapshot>[];

        if (companyStream == null) {
          return _buildResultsList(jobDocs);
        }

        return StreamBuilder<QuerySnapshot>(
          stream: companyStream,
          builder: (context, companySnapshot) {
            if (companySnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final companyDocs = companySnapshot.hasData ? companySnapshot.data!.docs : <DocumentSnapshot>[];

            final combinedDocs = <DocumentSnapshot>{}..addAll(jobDocs)..addAll(companyDocs);

            return _buildResultsList(combinedDocs.toList());
          },
        );
      },
    );
  }

  Widget _buildResultsList(List<DocumentSnapshot> jobDocs) {
    if (jobDocs.isEmpty) {
      return Center(
        child: Text(
          query.isEmpty ? 'No jobs available in this category' : 'No jobs found for "$query"',
        ),
      );
    }

    return ListView.builder(
      itemCount: jobDocs.length,
      itemBuilder: (context, index) {
        final job = jobDocs[index].data() as Map<String, dynamic>;
        return ListTile(
          title: Text(job['jobTitle'] ?? 'No title'),
          subtitle: Text(job['company'] ?? 'No company'),
          trailing: Text(job['salaryRange'] ?? 'No salary range'),
          onTap: () {
            // Navigate to job details
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GraduateJobDetails(job: job),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  void showResults(BuildContext context) {
    super.showResults(context);
  }

  @override
  Widget buildRecentSuggestions(BuildContext context) {
    return Container();
  }
}
