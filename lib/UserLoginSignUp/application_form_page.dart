import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart'; // Import FilePicker
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ApplicationFormPage extends StatefulWidget {
  final User user;
  final String jobTitle;
  final String company;
  final String employerId;
  final String companyLogoUrl;

  ApplicationFormPage({
    required this.user,
    required this.jobTitle,
    required this.company,
    required this.employerId,
    required this.companyLogoUrl,
  });

  @override
  _ApplicationFormPageState createState() => _ApplicationFormPageState();
}

class _ApplicationFormPageState extends State<ApplicationFormPage> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? _formData;
  File? _resumeFile;
  String? resumeLink;

  // Controllers for editable fields
  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _ageController;
  late TextEditingController _genderController;
  late TextEditingController _usernameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _emailController;
  late TextEditingController _coverLetterController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with data
    _fetchUserData();
    _coverLetterController = TextEditingController();
  }

  @override
  void dispose() {
    // Dispose controllers
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _usernameController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _coverLetterController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      // Get user's document from 'Applicants' collection
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Applicants')
          .doc(widget.user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _formData = userDoc.data()! as Map<String, dynamic>?;

          // Initialize controllers with user data
          _firstNameController = TextEditingController(text: _formData?['firstName']);
          _middleNameController = TextEditingController(text: _formData?['middleName']);
          _lastNameController = TextEditingController(text: _formData?['lastName']);
          _ageController = TextEditingController(text: _formData?['age']);
          _genderController = TextEditingController(text: _formData?['gender']);
          _usernameController = TextEditingController(text: _formData?['username']);
          _addressController = TextEditingController(text: _formData?['address']);
          _phoneNumberController = TextEditingController(text: _formData?['phoneNumber']);
          _emailController = TextEditingController(text: _formData?['email']);
        });
      }

      // Get user's resume document from 'Applicants_Resume' collection
      DocumentSnapshot resumeDoc = await FirebaseFirestore.instance
          .collection('Applicants_Resume')
          .doc(widget.user.uid)
          .get();

      if (resumeDoc.exists) {
        setState(() {
          resumeLink = resumeDoc['resumeUrl'];
        });
      }
    } catch (e) {
      print("Failed to fetch user data: $e");
    }
  }

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // Only allow PDF files
    );

    if (result != null) {
      setState(() {
        _resumeFile = File(result.files.single.path!);
        _uploadResume(); // Upload the selected file immediately
      });
    }
  }

  Future<String?> _uploadResume() async {
    if (_resumeFile == null) return null;
    final ref = FirebaseStorage.instance
        .ref()
        .child('resumes')
        .child('${widget.user.uid}.pdf');
    await ref.putFile(_resumeFile!);
    return await ref.getDownloadURL();
  }

  Future<void> _submitApplication() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      try {
        String? uploadedResumeUrl = await _uploadResume();

        // Prepare the application data
        Map<String, dynamic> application = {
          'name': [
            _firstNameController.text,
            _middleNameController.text,
            _lastNameController.text
          ].where((name) => name.isNotEmpty).join(' '),
          'email': _emailController.text,
          'address': _addressController.text,
          'age': _ageController.text,
          'username': _usernameController.text,
          'gender': _genderController.text,
          'phoneNumber': _phoneNumberController.text,
          'resumeLink': uploadedResumeUrl ?? resumeLink ?? '',
          'applicantsId': widget.user.uid, // Store the user's ID for reference
          'appliedAt': Timestamp.now(), // Add timestamp for submission
          'jobTitle': widget.jobTitle, // Add jobTitle
          'company': widget.company, // Add company
          'employerId': widget.employerId, // Add employerId
          'applicationStatus': 'Under Review',
          'coverLetter': _coverLetterController.text,
          'companyLogoUrl' : widget.companyLogoUrl
        };

        // Submit the application to Firestore collection 'Job_Applicants'
        await FirebaseFirestore.instance.collection('Job_Applicants').add(application);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application Submitted!')),
        );

        // Optionally, navigate back or to another page
        Navigator.pop(context);
      } catch (e) {
        // Show error message if submission fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit application: $e')),
        );
      }
    }
  }

  // Helper method to build user info fields
  Widget _buildUserInfoField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Application Form'),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_formData != null) ...[
                _buildUserInfoField('First Name', _firstNameController),
                _buildUserInfoField('Middle Name', _middleNameController),
                _buildUserInfoField('Last Name', _lastNameController),
                _buildUserInfoField('Age', _ageController),
                _buildUserInfoField('Gender', _genderController),
                _buildUserInfoField('Username', _usernameController),
                _buildUserInfoField('Address', _addressController),
                _buildUserInfoField('Phone Number', _phoneNumberController),
                _buildUserInfoField('Email', _emailController),
              ],
              SizedBox(height: 16),
              TextFormField(
                controller: _coverLetterController,
                decoration: InputDecoration(labelText: 'Cover Letter'),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a cover letter';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: _pickResume,
                child: Text(_resumeFile == null ? 'Upload Resume' : 'Resume Selected: ${_resumeFile!.path.split('/').last}'),
              ),
              SizedBox(height: 16),
              if (_resumeFile != null)
                Container(
                  height: 600, // Adjust height as needed
                  child: SfPdfViewer.file(_resumeFile!),
                )
              else if (resumeLink != null && resumeLink!.isNotEmpty)
                Container(
                  height: 600, // Adjust height as needed
                  child: SfPdfViewer.network(resumeLink!),
                )
              else
                Text('No resume available'),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitApplication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Submit Application',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
