import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:anap/UserLoginSignUp/userHomepage.dart';

class UploadResumeScreen extends StatefulWidget {
  final String userId; // Pass userId as a String

  UploadResumeScreen({required this.userId});

  @override
  _UploadResumeScreenState createState() => _UploadResumeScreenState();
}

class _UploadResumeScreenState extends State<UploadResumeScreen> {
  File? _resumeFile;
  bool _isUploading = false;
  String status = 'Graduate';
  List<String> selectedCategories = [];
  GlobalKey _pdfViewKey = GlobalKey(); // Unique key for PDFView

  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  String _startDateText = "Select Start Date";
  String _endDateText = "Select End Date";
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> _experienceList = [];

  final List<String> graduateCategories = [
    'Finance', 'Supermarket', 'Healthcare', 'Arts', 'Dentist',
    'Agriculture', 'Business', 'Hospitality', 'Computer'
  ];

  final List<String> undergraduateCategories = [
    'Public Market', 'SuperMarket', 'Food', 'Arts',
    'Fabrication', 'Freelance'
  ];

  Future<User?> _getUser() async {
    return FirebaseAuth.instance.currentUser;
  }

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _resumeFile = File(result.files.single.path!);
        _pdfViewKey = GlobalKey(); // Reset the key for PDFView
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchExperiences();
  }
  Future<void> _uploadResume() async {
    final user = await _getUser();
    if (user == null) {
      print("Error: User not logged in");
      return;
    }

    if (selectedCategories.isEmpty) {
      print("Error: No categories selected");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one category')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String? downloadUrl;
      if (_resumeFile != null) {
        print("Uploading resume to Firebase Storage...");
        final ref = FirebaseStorage.instance
            .ref()
            .child('resumes')
            .child('${widget.userId}_resume.${_resumeFile!.path.split('.').last}');
        await ref.putFile(_resumeFile!);

        print("Fetching download URL...");
        downloadUrl = await ref.getDownloadURL();
        print("Resume uploaded successfully. URL: $downloadUrl");
      }

      print("Uploading details to Firestore...");
      Map<String, dynamic> data = {
        'applicantUid': widget.userId,
        'status': status,
        'category': selectedCategories.join(', '),
        'experience': _experienceList,
      };

      if (downloadUrl != null) {
        data['resumeUrl'] = downloadUrl;
      }

      await FirebaseFirestore.instance.collection('Applicants_Resume').doc(widget.userId).set(data);

      print("Details uploaded to Firestore successfully");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resume and experience uploaded successfully')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(user: user),
        ),
      );
    } catch (e) {
      print("Error during resume upload: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload resume: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }



  void _onCategorySelected(String category) {
    setState(() {
      if (selectedCategories.contains(category)) {
        selectedCategories.remove(category);
      } else {
        selectedCategories.add(category);
      }
    });
  }
  void _fetchExperiences() {
    FirebaseFirestore.instance
        .collection('Applicants_Resume')
        .doc(widget.userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _experienceList = List<Map<String, dynamic>>.from(
              snapshot.data()?['experience'] ?? []);
        });
      }
    });
  }

  Future<void> _updateExperiencesInFirestore() async {
    try {
      await FirebaseFirestore.instance
          .collection('Applicants_Resume')
          .doc(widget.userId)
          .update({'experience': _experienceList});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Experiences updated successfully')),
      );
    } catch (e) {
      print("Error updating experiences: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update experiences')),
      );
    }
  }


  void _addExperience() {
    if (_experienceController.text.isNotEmpty &&
        _companyController.text.isNotEmpty &&
        _startDate != null &&
        _endDate != null &&
        _startDate!.isBefore(_endDate!)) {
      final years = _endDate!.year - _startDate!.year;
      final newExperience = {
        'experience': _experienceController.text,
        'years': years,
        'company': _companyController.text,
        'startDate': '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
        'endDate': '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
      };

      setState(() {
        _experienceList.add(newExperience);
      });

      _updateExperiencesInFirestore();
    }
  }


  Future<void> _showDatePicker(BuildContext context, String type) async {
    DateTime? selectedDate = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (_) {
        DateTime tempDate = DateTime.now();
        return Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 250,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: DateTime.now(),
                  onDateTimeChanged: (dateTime) {
                    tempDate = dateTime;
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, tempDate);
                    },
                    child: Text("OK"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        if (type == "start") {
          _startDate = selectedDate;
          _startDateText =
          '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}';
        } else {
          _endDate = selectedDate;
          _endDateText =
          '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = status == 'Graduate' ? graduateCategories : undergraduateCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Job', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Status and Categories Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: ['Graduate', 'Undergraduate']
                            .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            status = value!;
                            selectedCategories.clear();
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: Text(
                          "Select Category",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: categories.map((cat) {
                          final isSelected = selectedCategories.contains(cat);
                          return ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              _onCategorySelected(cat);
                            },
                            selectedColor: Colors.blue.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected ? Colors.blue : Colors.grey,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Experience Input Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Add Experience",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _experienceController,
                        decoration: InputDecoration(
                          labelText: 'Experience',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _companyController,
                        decoration: InputDecoration(
                          labelText: 'Company',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Start Date",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      _showDatePicker(context, "start"),
                                  child: Text(_startDateText),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "End Date",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextButton(
                                  onPressed: () => _showDatePicker(context, "end"),
                                  child: Text(_endDateText),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _addExperience,
                        icon: Icon(Icons.add, color: Colors.white),
                        label: Text("Add", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                      ),
                      if (_experienceList.isNotEmpty)
                        ..._experienceList.map((exp) => ListTile(
                          title: Text(exp['experience']),
                          subtitle: Text(
                            '${exp['company']}\n${exp['startDate']} - ${exp['endDate']}\n${exp['years']} ${exp['years'] == 1 ? 'year' : 'years'}',
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _experienceList.remove(exp);
                              });
                            },
                          ),
                        )),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickResume,
                icon: Icon(
                  Icons.upload_file,
                  color: Colors.white,
                ),
                label: Text(
                  'Select Resume',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.red,
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomePage(user: FirebaseAuth.instance.currentUser!),
                    ),
                  );
                },
                child: Text('Skip'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: Colors.black,
                ),
              ),
              if (_resumeFile != null) ...[
                SizedBox(height: 16),
                Text(
                  'Resume selected: ${_resumeFile!.path.split('/').last}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Container(
                  height: 400,
                  child: PDFView(
                    key: _pdfViewKey,
                    filePath: _resumeFile!.path,
                    enableSwipe: true,
                    swipeHorizontal: true,
                    autoSpacing: false,
                    pageFling: false,
                    onRender: (pages) {
                      setState(() {});
                    },
                    onError: (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error displaying PDF')),
                      );
                    },
                    onPageError: (page, error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error on page $page')),
                      );
                    },
                  ),
                ),
              ],
              if (_isUploading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _uploadResume,
                icon: Icon(Icons.cloud_upload, color: Colors.white),
                label: Text('Submit', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
