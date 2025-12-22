import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_widgets.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final DatabaseService _db = DatabaseService();
  String _searchQuery = "";
  String _selectedFilter = "All";

  final Map<String, List<String>> _daftarKelas = {
    'IPA': ['IPA 1', 'IPA 2', 'IPA 3', 'IPA 4', 'IPA 5', 'IPA 6', 'IPA 7'],
    'IPS': ['IPS 1', 'IPS 2', 'IPS 3', 'IPS 4', 'IPS 5', 'IPS 6', 'IPS 7'],
  };

  // --- FITUR EXPORT PDF (FIXED ERROR MOUNTED) ---
  Future<void> _exportToPDF(List<QueryDocumentSnapshot> students) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pdfContext) { // Diganti jadi pdfContext agar tidak bentrok
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start, // Fix Error mounted di sini
            children: [
              pw.Text("Laporan Data Siswa", 
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text("Filter: $_selectedFilter"),
              pw.Text("Total Siswa: ${students.length}"),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Nama', 'Kelas', 'Umur'],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                data: students.map((s) {
                  final data = s.data() as Map<String, dynamic>;
                  return [
                    data['name'] ?? '',
                    data['class'] ?? '',
                    data['age']?.toString() ?? ''
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_Siswa_${_selectedFilter}.pdf'
    );
  }

  Future<String?> uploadFile(PlatformFile file, String studentName) async {
    try {
      final path = 'documents/$studentName/${file.name}';
      final ref = FirebaseStorage.instance.ref().child(path);
      if (file.bytes != null) {
        await ref.putData(file.bytes!);
      } else if (file.path != null) {
        await ref.putFile(File(file.path!));
      }
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  void _showFormDialog({String? id, Map<String, dynamic>? data}) {
    final nameCtrl = TextEditingController(text: data?['name'] ?? '');
    final ageCtrl = TextEditingController(text: data?['age']?.toString() ?? '');
    String? selectedMajor;
    String? selectedClassValue = data?['class'];

    if (id != null && selectedClassValue != null) {
      if (selectedClassValue.contains('IPA')) selectedMajor = 'IPA';
      else if (selectedClassValue.contains('IPS')) selectedMajor = 'IPS';
    }

    Map<String, dynamic> currentDocs = data?['documents'] != null
        ? Map<String, dynamic>.from(data!['documents'])
        : {};

    bool isEdit = id != null;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEdit ? "Update Student Data" : "Add New Student",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 20),
                  CustomTextField(controller: nameCtrl, hint: "Full Name", icon: Icons.person),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: UniqueKey(),
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.account_tree, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    hint: const Text("Select Major", style: TextStyle(color: Colors.grey)),
                    initialValue: selectedMajor,
                    items: ['IPA', 'IPS'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) {
                      setModalState(() {
                        selectedMajor = val;
                        selectedClassValue = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: UniqueKey(),
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.class_, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    hint: const Text("Select Class", style: TextStyle(color: Colors.grey)),
                    initialValue: selectedClassValue,
                    items: selectedMajor == null
                        ? []
                        : _daftarKelas[selectedMajor]!.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: selectedMajor == null ? null : (val) => setModalState(() => selectedClassValue = val),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(controller: ageCtrl, hint: "Age", icon: Icons.cake, type: TextInputType.number),
                  const SizedBox(height: 24),
                  isUploading
                      ? const Center(child: LinearProgressIndicator(color: Color(0xFFD946EF)))
                      : OutlinedButton.icon(
                          onPressed: () async {
                            if (nameCtrl.text.isEmpty) return;
                            FilePickerResult? result = await FilePicker.platform.pickFiles();
                            if (result != null) {
                              setModalState(() => isUploading = true);
                              String? url = await uploadFile(result.files.single, nameCtrl.text);
                              if (url != null) {
                                setModalState(() {
                                  currentDocs[result.files.single.name] = url;
                                  isUploading = false;
                                });
                              } else {
                                setModalState(() => isUploading = false);
                              }
                            }
                          },
                          icon: const Icon(Icons.upload_file, color: Color(0xFFD946EF)),
                          label: const Text("Upload Document", style: TextStyle(color: Colors.white)),
                        ),
                  const SizedBox(height: 24),
                  NeonButton(
                    text: isEdit ? "Update Data" : "Save Student",
                    onPressed: isUploading || selectedClassValue == null
                        ? () {}
                        : () async {
                            if (isEdit) {
                              await _db.updateStudent(id!, nameCtrl.text, selectedClassValue!, int.parse(ageCtrl.text), currentDocs);
                            } else {
                              await _db.addStudent(nameCtrl.text, selectedClassValue!, int.parse(ageCtrl.text));
                            }
                            // FIX: Guard context with mounted check
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          },
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Students Data", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: _db.getStudents(),
            builder: (context, snapshot) {
              return IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                onPressed: () {
                  if (snapshot.hasData) {
                    var filteredList = snapshot.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      bool matchesSearch = data['name'].toString().toLowerCase().contains(_searchQuery);
                      bool matchesFilter = _selectedFilter == "All" || data['class'].toString().contains(_selectedFilter);
                      return matchesSearch && matchesFilter;
                    }).toList();
                    _exportToPDF(filteredList);
                  }
                },
              );
            }
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        backgroundColor: const Color(0xFFD946EF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search student name...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ["All", "IPA", "IPS"].map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (val) => setState(() => _selectedFilter = filter),
                    selectedColor: const Color(0xFFD946EF),
                    backgroundColor: const Color(0xFF1E1E1E),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(color: _selectedFilter == filter ? Colors.white : Colors.grey),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.getStudents(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var students = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  bool matchesSearch = data['name'].toString().toLowerCase().contains(_searchQuery);
                  bool matchesFilter = _selectedFilter == "All" || data['class'].toString().contains(_selectedFilter);
                  return matchesSearch && matchesFilter;
                }).toList();
                if (students.isEmpty) return const Center(child: Text("No students found.", style: TextStyle(color: Colors.grey)));
                return ListView.builder(
                  itemCount: students.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    var data = students[index].data() as Map<String, dynamic>;
                    String id = students[index].id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: Colors.grey[900], child: const Icon(Icons.person, color: Colors.white)),
                        title: Text(data['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text("${data['class']} • ${data['age']} Thn", style: const TextStyle(color: Colors.grey)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => _showFormDialog(id: id, data: data)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _db.deleteStudent(id)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}