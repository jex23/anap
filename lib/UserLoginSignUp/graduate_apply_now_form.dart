import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class GraduateApplyNowForm extends StatefulWidget {
  final Map<String, dynamic> job;
  final User? user;
  final String employerId; // Add this line

  GraduateApplyNowForm({
    required this.job,
    required this.user,
    required this.employerId, // Add this line
  });

  @override
  _GraduateApplyNowFormState createState() => _GraduateApplyNowFormState();
}

class _GraduateApplyNowFormState extends State<GraduateApplyNowForm> {
  final _formKey = GlobalKey<FormState>();
  final _coverLetterController = TextEditingController();
  File? _resumeFile;
  String? _resumeUrl;
  Map<String, dynamic>? _userData;
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _usernameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();


  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      var userDoc = await FirebaseFirestore.instance.collection('Applicants').doc(widget.user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data();

          _firstNameController.text = _userData?['firstName'] ?? '';
          _middleNameController.text = _userData?['middleName'] ?? '';
          _lastNameController.text = _userData?['lastName'] ?? '';
          _ageController.text = _userData?['age'] ?? '';
          _genderController.text = _userData?['gender'] ?? '';
          _usernameController.text = _userData?['username'] ?? '';
          _addressController.text = _userData?['address'] ?? '';
          _phoneNumberController.text = _userData?['phoneNumber'] ?? '';
          _emailController.text = _userData?['email'] ?? '';
        });

        var resumeDoc = await FirebaseFirestore.instance.collection('Applicants_Resume').doc(widget.user!.uid).get();
        if (resumeDoc.exists) {
          setState(() {
            _resumeUrl = resumeDoc.data()?['resumeUrl'];
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }


  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _resumeFile = File(result.files.single.path!);
        _resumeUrl = null; // Clear the Firestore URL if a new file is picked
      });
    }
  }

  Future<String?> _uploadResume() async {
    if (_resumeFile != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('resumes/${widget.user?.uid}/${DateTime.now().millisecondsSinceEpoch}.pdf');
      await storageRef.putFile(_resumeFile!);
      final resumeUrl = await storageRef.getDownloadURL();
      // Update Firestore with the new resume URL
      await FirebaseFirestore.instance.collection('Applicants_Resume').doc(widget.user?.uid).set({
        'resumeUrl': resumeUrl,
      });
      return resumeUrl;
    }
    return null;
  }

  Future<void> _applyForJob() async {
    if (_formKey.currentState?.validate() ?? false) {
      String? resumeUrl;
      if (_resumeFile != null) {
        resumeUrl = await _uploadResume();
      } else if (_resumeUrl != null) {
        resumeUrl = _resumeUrl;
      }

      final application = {
        'applicantsId': widget.user?.uid,
        'employerId': widget.employerId,
        'name': '${_firstNameController.text} ${_middleNameController.text} ${_lastNameController.text}'.trim(),
        'age': _ageController.text,
        'gender': _genderController.text,
        'username': _usernameController.text,
        'address': _addressController.text,
        'phoneNumber': _phoneNumberController.text,
        'email': _emailController.text,
        'coverLetter': _coverLetterController.text,
        'resumeUrl': resumeUrl,
        'applicationStatus': 'Under Review',
        'appliedAt': FieldValue.serverTimestamp(),
        'jobTitle': widget.job['jobTitle'],
        'company': widget.job['company'],
        'companyLogoUrl' : widget.job['companyLogoUrl']

      };

      await FirebaseFirestore.instance.collection('Job_Applicants').add(application);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Application Submitted')));
      Navigator.of(context).pop();
    }
  }

  Widget _buildEditableUserInfoField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }


  Widget _buildUserInfoField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: value ?? '',
        decoration: InputDecoration(
          labelText: label,
        ),
        readOnly: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[300],
        title: Text('Apply for Job'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_userData != null) ...[
                _buildEditableUserInfoField('First Name', _firstNameController),
                _buildEditableUserInfoField('Middle Name', _middleNameController),
                _buildEditableUserInfoField('Last Name', _lastNameController),
                _buildEditableUserInfoField('Age', _ageController),
                _buildEditableUserInfoField('Gender', _genderController),
                _buildEditableUserInfoField('Username', _usernameController),
                _buildEditableUserInfoField('Address', _addressController),
                _buildEditableUserInfoField('Phone Number', _phoneNumberController),
                _buildEditableUserInfoField('Email', _emailController),
                SizedBox(height: 16),
              ],
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
              SizedBox(height: 16),
              GestureDetector(
                onTap: _pickResume,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_file),
                      SizedBox(width: 16),
                      Text(
                        _resumeFile == null ? 'Upload Resume' : 'Resume Attached',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              if (_resumeFile != null) ...[
                SizedBox(height: 16),
                Container(
                  height: 500, // Adjust height as needed
                  child: SfPdfViewer.file(_resumeFile!),
                ),
              ],
              if (_resumeUrl != null && _resumeFile == null) ...[
                SizedBox(height: 16),
                Container(
                  height: 500, // Adjust height as needed
                  child: SfPdfViewer.network(_resumeUrl!),
                ),
              ],
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _applyForJob,
                child: Text('Submit Application'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.red[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
