import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class AvailableForAnyoneApplyNowForm extends StatefulWidget {
  final Map<String, dynamic> job;
  final User? user;
  final String employerId;

  AvailableForAnyoneApplyNowForm({
    required this.job,
    required this.user,
    required this.employerId,
  });

  @override
  _AvailableForAnyoneApplyNowFormState createState() =>
      _AvailableForAnyoneApplyNowFormState();
}

class _AvailableForAnyoneApplyNowFormState
    extends State<AvailableForAnyoneApplyNowForm> {
  final _formKey = GlobalKey<FormState>();
  final _coverLetterController = TextEditingController();
  File? _resumeFile;
  String? _resumeUrl;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();

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
        'applicantId': widget.user?.uid,
        'employerId': widget.employerId,
        'name': '${_firstNameController.text} ${_lastNameController.text}'.trim(),
        'phoneNumber': _phoneNumberController.text,
        'email': _emailController.text,
        'coverLetter': _coverLetterController.text,
        'resumeUrl': resumeUrl,
        'applicationStatus': 'Under Review',
        'appliedAt': FieldValue.serverTimestamp(),
        'jobTitle': widget.job['jobTitle'],
        'company': widget.job['company'],
        'companyLogoUrl': widget.job['companyLogoUrl'],
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
              _buildEditableUserInfoField('First Name', _firstNameController),
              _buildEditableUserInfoField('Last Name', _lastNameController),
              _buildEditableUserInfoField('Phone Number', _phoneNumberController),
              _buildEditableUserInfoField('Email', _emailController),
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
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red[300],
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
