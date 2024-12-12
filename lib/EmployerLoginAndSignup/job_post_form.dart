import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class JobPostForm extends StatefulWidget {
  final User user;

  JobPostForm({required this.user});

  @override
  _JobPostFormState createState() => _JobPostFormState();
}

class _JobPostFormState extends State<JobPostForm> {
  final _formKey = GlobalKey<FormState>();
  String jobTitle = '';
  String company = '';
  String address = '';
  int? minSalary;
  int? maxSalary;
  String yearExperience = '';
  String aboutRole = '';
  String skills = '';
  String requirements = '';
  String status = 'Graduate';
  String category = '';
  String jobType = 'Full-Time';
  String jobSchedule = 'Monday to Friday';
  String salaryPaymentStyle = 'Daily'; // Default value
  File? companyLogo;

  final List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final List<String> graduateCategories = [
    'Finance',
    'Supermarket',
    'Healthcare',
    'Arts',
    'Dentist',
    'Agriculture',
    'Business',
    'Hospitality',
    'Computer',
  ];

  final List<String> undergraduateCategories = [
    'Public Market',
    'SuperMarket',
    'Food',
    'Arts',
    'Fabrication',
    'Freelance',
  ];

  final List<String> statusOptions = [
    'Undergraduate',
    'Graduate',
    'Available to Anyone',
  ];

  final List<String> salaryPaymentStyles = [
    'Daily',
    'Weekly',
    'Monthly',
    'Contractual',
  ];

  final Map<String, String> statusDisplayMap = {
    'Undergraduate': 'College Under-graduate/Techvo/K-12',
    'Graduate': 'Graduate',
    'Available to Anyone': 'Available to Anyone',
  };

  List<String> categoryOptions = [];
  String? selectedStartDay;
  String? selectedEndDay;

  @override
  void initState() {
    super.initState();
    categoryOptions = graduateCategories;
  }

  void _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        companyLogo = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('company_logos/${DateTime.now().millisecondsSinceEpoch}.png');
      await storageRef.putFile(image);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _submitJobPost() async {
    if (_formKey.currentState!.validate()) {
      if (companyLogo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please upload a company logo before submitting.')),
        );
        return;
      }

      _formKey.currentState!.save();

      String schedule = selectedStartDay != null && selectedEndDay != null
          ? '$selectedStartDay - $selectedEndDay'
          : 'Monday to Friday';
      String salaryRange = '$minSalary - $maxSalary';

      String? logoUrl;
      if (companyLogo != null) {
        logoUrl = await _uploadImage(companyLogo!);
      }

      try {
        await FirebaseFirestore.instance.collection('EmployerJobPost').add({
          'employerId': widget.user.uid,
          'jobTitle': jobTitle,
          'company': company,
          'address': address,
          'salaryRange': salaryRange,
          'salaryPaymentStyle': salaryPaymentStyle,
          'yearExperience': yearExperience,
          'aboutRole': aboutRole,
          'skills': skills,
          'requirements': requirements,
          'expiry': "Hiring",
          'status': status,
          'category': category,
          'jobType': jobType,
          'jobSchedule': schedule,
          'postedAt': Timestamp.now(),
          'companyLogoUrl': logoUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job post created successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating job post: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        constraints: BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red[300]!, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    'Create Job Post',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white30,
                    backgroundImage: companyLogo != null ? FileImage(companyLogo!) : null,
                    child: companyLogo == null
                        ? Icon(Icons.add_a_photo, size: 50, color: Colors.white)
                        : null,
                  ),
                ),
                SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: _pickImage,
                    child: Text(
                      'Upload Company Logo',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                _buildTextField('Job Title', onSaved: (value) => jobTitle = value!),
                _buildTextField('Company Name', onSaved: (value) => company = value!),
                _buildTextField('Address', onSaved: (value) => address = value!),
                _buildDropdownField(
                  label: 'Status',
                  value: status,
                  items: statusOptions,
                  onChanged: (value) {
                    setState(() {
                      status = value!;
                      if (status == 'Graduate') {
                        categoryOptions = graduateCategories;
                      } else if (status == 'Undergraduate') {
                        categoryOptions = undergraduateCategories;
                      } else if (status == 'Available to Anyone') {
                        categoryOptions = [
                          ...graduateCategories,
                          ...undergraduateCategories,
                        ];
                      }
                      category = '';
                    });
                  },
                ),
                _buildDropdownField(
                  label: 'Category',
                  value: category.isNotEmpty ? category : null,
                  items: categoryOptions,
                  onChanged: (value) => setState(() => category = value!),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        'Min Salary',
                        keyboardType: TextInputType.number,
                        onSaved: (value) => minSalary = int.tryParse(value!),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        'Max Salary',
                        keyboardType: TextInputType.number,
                        onSaved: (value) => maxSalary = int.tryParse(value!),
                      ),
                    ),
                  ],
                ),
                _buildDropdownField(
                  label: 'Salary Payment Style',
                  value: salaryPaymentStyle,
                  items: salaryPaymentStyles,
                  onChanged: (value) => setState(() => salaryPaymentStyle = value!),
                ),
                _buildTextField(
                  'Skills',
                  maxLines: 2,
                  onSaved: (value) => skills = value!,
                ),
                _buildTextField(
                  'Year of Experience',
                  keyboardType: TextInputType.number,
                  onSaved: (value) => yearExperience = value!,
                ),
                _buildTextField(
                  'About Role',
                  maxLines: 3,
                  onSaved: (value) => aboutRole = value!,
                ),
                _buildTextField(
                  'Requirements',
                  maxLines: 2,
                  onSaved: (value) => requirements = value!,
                ),
                _buildDropdownField(
                  label: 'Job Type',
                  value: jobType,
                  items: ['Full-Time', 'Part-Time', 'Internship'],
                  onChanged: (value) => setState(() => jobType = value!),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Start Day',
                        value: selectedStartDay,
                        items: daysOfWeek,
                        onChanged: (value) => setState(() => selectedStartDay = value!),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _buildDropdownField(
                        label: 'End Day',
                        value: selectedEndDay,
                        items: daysOfWeek,
                        onChanged: (value) => setState(() => selectedEndDay = value!),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitJobPost,
                    child: Text('Submit Job Post'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      backgroundColor: Colors.red[300],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, {
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    FormFieldSetter<String>? onSaved,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          suffixIcon: suffixIcon,
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        value: value,
        items: items
            .map((item) => DropdownMenuItem(
          value: item,
          child: Text(item),
        ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
