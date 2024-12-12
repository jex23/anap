import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class EditAccountScreen extends StatefulWidget {
  final User user;

  EditAccountScreen({required this.user});

  @override
  _EditAccountScreenState createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _formData = {};
  File? _imageFile;
  bool _isLoading = false;
  String _selectedGender = 'Male';
  String? resumeUrl;
  String? status;
  String? category;
  GlobalKey _pdfViewKey = GlobalKey(); // Unique key for PDFView

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    var userDoc = await FirebaseFirestore.instance.collection('Applicants').doc(widget.user.uid).get();
    if (userDoc.exists) {
      setState(() {
        _formData = userDoc.data()!;
        _selectedGender = _formData['gender'] ?? 'Male'; // Default to 'Male' if not set
      });
    }
    var resumeDoc = await FirebaseFirestore.instance.collection('Applicants_Resume').doc(widget.user.uid).get();
    if (resumeDoc.exists) {
      setState(() {
        resumeUrl = resumeDoc['resumeUrl'];
        status = resumeDoc['status'];
        category = resumeDoc['category'];
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateUserData() async {
    final updatedData = {
      'firstName': _formData['First Name'] ?? _formData['firstName'],
      'middleName': _formData['Middle Name'] ?? _formData['middleName'],
      'lastName': _formData['Last Name'] ?? _formData['lastName'],
      'age': _formData['Age'] ?? _formData['age'],
      'gender': _selectedGender,
      'username': _formData['Username'] ?? _formData['username'],
      'address': _formData['Address'] ?? _formData['address'],
      'phoneNumber': _formData['Phone Number'] ?? _formData['phoneNumber'],
      'photoUrl': _imageFile != null ? await _uploadImage() : _formData['photoUrl'],
    };

    await FirebaseFirestore.instance.collection('Applicants').doc(widget.user.uid).update(updatedData);
    _fetchUserData();
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;
    final ref = FirebaseStorage.instance
        .ref()
        .child('user_images')
        .child('${widget.user.uid}.jpg');
    await ref.putFile(_imageFile!);
    return await ref.getDownloadURL();
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Edit Account', style: TextStyle(color: Colors.redAccent)),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : NetworkImage(_formData['photoUrl'] ?? '') as ImageProvider,
                      child: _imageFile == null
                          ? Icon(Icons.camera_alt, size: 50, color: Colors.white)
                          : null,
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildTextField('First Name', _formData['firstName']),
                  _buildTextField('Middle Name', _formData['middleName']),
                  _buildTextField('Last Name', _formData['lastName']),
                  _buildTextField('Age', _formData['age']),
                  _buildGenderDropdown(),
                  _buildTextField('Username', _formData['username']),
                  _buildPhoneNumberField(),
                  _buildTextField('Address', _formData['address']), // Added address field
                ],
              ),
            ),
          ),
          actions: <Widget>[
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    _isLoading = true;
                  });
                  await _updateUserData();
                  setState(() {
                    _isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Updated successfully!')),
                  );
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Change button color to red
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: value ?? '',
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.redAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.redAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.redAccent),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label cannot be empty';
          }
          return null;
        },
        onChanged: (newValue) {
          setState(() {
            _formData[label] = newValue;
          });
        },
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: InputDecoration(
          labelText: 'Gender',
          labelStyle: TextStyle(color: Colors.redAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.redAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.redAccent),
          ),
        ),
        items: ['Male', 'Female', 'Other']
            .map((gender) => DropdownMenuItem(
          value: gender,
          child: Text(gender),
        ))
            .toList(),
        onChanged: (newValue) {
          setState(() {
            _selectedGender = newValue!;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a gender';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: _formData['phoneNumber'] ?? '',
        decoration: InputDecoration(
          labelText: 'Phone Number',
          labelStyle: TextStyle(color: Colors.redAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.redAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.redAccent),
          ),
        ),
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
          LengthLimitingTextInputFormatter(11), // Allow up to 11 characters
        ],
        validator: (value) {
          final phoneRegExp = RegExp(r'^09[0-9]{9}$');
          if (value == null || value.isEmpty) {
            return 'Phone number cannot be empty';
          } else if (!phoneRegExp.hasMatch(value)) {
            return 'Invalid phone number. Format: 09XXXXXXXXX';
          }
          return null;
        },
        onChanged: (newValue) {
          setState(() {
            _formData['phoneNumber'] = newValue;
          });
        },
      ),
    );
  }



  Future<void> _viewPdf(String url) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PDFViewPage(pdfUrl: url),
      ),
    );
  }

  Widget _buildStatusCategoryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(Icons.info, color: Colors.redAccent),
        title: Text('Application Details'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${status ?? 'N/A'}'),
            Text('Category: ${category ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Information', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(child: CircleAvatar(
              radius: 50,
              backgroundImage: _imageFile != null
                  ? FileImage(_imageFile!)
                  : NetworkImage(_formData['photoUrl'] ?? '') as ImageProvider,
            ),),
            SizedBox(height: 20),
            _buildUserInfoField('First Name', _formData['firstName']),
            _buildUserInfoField('Middle Name', _formData['middleName']),
            _buildUserInfoField('Last Name', _formData['lastName']),
            _buildUserInfoField('Age', _formData['age']),
            _buildUserInfoField('Gender', _formData['gender']),
            _buildUserInfoField('Username', _formData['username']),
            _buildUserInfoField('Address', _formData['address']),
            _buildUserInfoField('Phone Number', _formData['phoneNumber']),
            _buildUserInfoField('Email', _formData['email']), // Display email
            SizedBox(height: 20),
            _buildStatusCategoryCard(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showEditDialog,
        backgroundColor: Colors.redAccent,
        child: Icon(Icons.edit),
        tooltip: 'Edit Details',
      ),
    );
  }

  Widget _buildUserInfoField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '$label: ${value ?? 'N/A'}',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class PDFViewPage extends StatelessWidget {
  final String pdfUrl;

  PDFViewPage({required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Resume', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
      ),
      body: PDFView(
        filePath: pdfUrl,
        key: Key(pdfUrl),
      ),
    );
  }
}
