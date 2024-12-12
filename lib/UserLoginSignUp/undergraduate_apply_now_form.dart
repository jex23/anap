import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class UndergraduateApplyNowForm extends StatefulWidget {
  final Map<String, dynamic> job;
  final User? user;
  final String employerId;

  UndergraduateApplyNowForm({
    required this.job,
    required this.user,
    required this.employerId,
  });

  @override
  _UndergraduateApplyNowFormState createState() => _UndergraduateApplyNowFormState();
}

class _UndergraduateApplyNowFormState extends State<UndergraduateApplyNowForm> {
  final _formKey = GlobalKey<FormState>();
  final _coverLetterController = TextEditingController();
  File? _resumeFile;
  String? _resumeUrl;
  Map<String, dynamic>? _userData;

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
        });

        // Fetch resume URL if available
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
        _resumeUrl = null;  // Clear the Firestore URL if a new file is picked
      });
    }
  }

  Future<String?> _uploadResume() async {
    if (_resumeFile != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('undergraduate_resumes/${widget.user?.uid}/${DateTime.now().millisecondsSinceEpoch}.pdf');
      await storageRef.putFile(_resumeFile!);
      final resumeUrl = await storageRef.getDownloadURL();
      // Update Firestore with the new resume URL
      await FirebaseFirestore.instance.collection('Undergraduate_Applicants_Resume').doc(widget.user?.uid).set({
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
        'name': '${_userData?['firstName'] ?? ''} ${_userData?['middleName'] ?? ''} ${_userData?['lastName'] ?? ''}'.trim(),
        'age': _userData?['age'],
        'gender': _userData?['gender'],
        'username': _userData?['username'],
        'address': _userData?['address'],
        'phoneNumber': _userData?['phoneNumber'],
        'email': _userData?['email'],
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

  Widget _buildUserInfoField(String label, String? value, Function(String)? onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: value ?? '',
        decoration: InputDecoration(
          labelText: label,
        ),
        onChanged: onChanged,  // Always allow the fields to be edited
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
                _buildUserInfoField('First Name', _userData?['firstName'], (value) {
                  setState(() {
                    _userData?['firstName'] = value;
                  });
                }),
                _buildUserInfoField('Middle Name', _userData?['middleName'], (value) {
                  setState(() {
                    _userData?['middleName'] = value;
                  });
                }),
                _buildUserInfoField('Last Name', _userData?['lastName'], (value) {
                  setState(() {
                    _userData?['lastName'] = value;
                  });
                }),
                _buildUserInfoField('Age', _userData?['age'], (value) {
                  setState(() {
                    _userData?['age'] = value;
                  });
                }),
                _buildUserInfoField('Gender', _userData?['gender'], (value) {
                  setState(() {
                    _userData?['gender'] = value;
                  });
                }),
                _buildUserInfoField('Username', _userData?['username'], (value) {
                  setState(() {
                    _userData?['username'] = value;
                  });
                }),
                _buildUserInfoField('Address', _userData?['address'], (value) {
                  setState(() {
                    _userData?['address'] = value;
                  });
                }),
                _buildUserInfoField('Phone Number', _userData?['phoneNumber'], (value) {
                  setState(() {
                    _userData?['phoneNumber'] = value;
                  });
                }),
                _buildUserInfoField('Email', _userData?['email'], (value) {
                  setState(() {
                    _userData?['email'] = value;
                  });
                }),
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
                  height: 500,
                  child: SfPdfViewer.file(_resumeFile!),
                ),
              ],
              if (_resumeUrl != null && _resumeFile == null) ...[
                SizedBox(height: 16),
                Container(
                  height: 500,
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
