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

  // Daftar Kelas Tetap Ada untuk Keperluan Dropdown Input/Edit
  final Map<String, List<String>> _daftarKelas = {
    'IPA': ['IPA 1', 'IPA 2', 'IPA 3', 'IPA 4', 'IPA 5', 'IPA 6', 'IPA 7'],
    'IPS': ['IPS 1', 'IPS 2', 'IPS 3', 'IPS 4', 'IPS 5', 'IPS 6', 'IPS 7'],
  };

  // --- FITUR EXPORT PDF ---
  Future<void> _exportToPDF(List<QueryDocumentSnapshot> students) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pdfContext) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Laporan Data Siswa", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text("Filter: $_selectedFilter | Total: ${students.length}"),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Nama', 'Kelas', 'Umur'],
              data: students.map((s) {
                final data = s.data() as Map<String, dynamic>;
                return [data['name'] ?? '', data['class'] ?? '', data['age']?.toString() ?? ''];
              }).toList(),
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Laporan_Siswa.pdf');
  }

  // Logika Upload File
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

  // Dialog Form Input & Edit
  void _showFormDialog({String? id, Map<String, dynamic>? data}) {
    final nameCtrl = TextEditingController(text: data?['name'] ?? '');
    final ageCtrl = TextEditingController(text: data?['age']?.toString() ?? '');
    String? selectedMajor;
    String? selectedClassValue;

    // Fix Dropdown Value Mapping
    if (id != null && data?['class'] != null) {
      String fullClass = data!['class'];
      if (fullClass.contains('IPA')) selectedMajor = 'IPA';
      else if (fullClass.contains('IPS')) selectedMajor = 'IPS';

      if (selectedMajor != null) {
        String suffix = fullClass.replaceAll('$selectedMajor ', '').trim();
        if (_daftarKelas[selectedMajor]!.contains(suffix)) {
          selectedClassValue = suffix;
        }
      }
    }

    bool isEdit = id != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isEdit ? "Update Student" : "Add Student", 
                style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              CustomTextField(controller: nameCtrl, hint: "Full Name", icon: Icons.person),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(color: Colors.white),
                value: selectedMajor,
                hint: const Text("Select Major", style: TextStyle(color: Colors.grey)),
                items: ['IPA', 'IPS'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) => setModalState(() { selectedMajor = val; selectedClassValue = null; }),
                decoration: InputDecoration(filled: true, fillColor: Colors.grey[900], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF1E1E1E),
                style: const TextStyle(color: Colors.white),
                value: selectedClassValue,
                hint: const Text("Select Class", style: TextStyle(color: Colors.grey)),
                items: selectedMajor == null ? [] : _daftarKelas[selectedMajor]!.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setModalState(() => selectedClassValue = val),
                decoration: InputDecoration(filled: true, fillColor: Colors.grey[900], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 16),
              CustomTextField(controller: ageCtrl, hint: "Age", icon: Icons.cake, type: TextInputType.number),
              const SizedBox(height: 24),
              NeonButton(
                text: "Save Data",
                onPressed: () async {
                  if (selectedClassValue == null || selectedMajor == null) return;
                  String finalClass = "$selectedMajor $selectedClassValue";
                  if (isEdit) await _db.updateStudent(id!, nameCtrl.text, finalClass, int.parse(ageCtrl.text), data?['documents'] ?? {});
                  else await _db.addStudent(nameCtrl.text, finalClass, int.parse(ageCtrl.text));
                  if (mounted) Navigator.pop(context);
                },
              )
            ],
          ),
        ),
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
          // Tombol PDF tetap dipertahankan
          StreamBuilder<QuerySnapshot>(
            stream: _db.getStudents(),
            builder: (context, snapshot) => IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              onPressed: () {
                if (snapshot.hasData) {
                  var list = snapshot.data!.docs.where((doc) {
                    var d = doc.data() as Map<String, dynamic>;
                    bool matchesSearch = d['name'].toString().toLowerCase().contains(_searchQuery);
                    bool matchesFilter = _selectedFilter == "All" || d['class'].toString().contains(_selectedFilter);
                    return matchesSearch && matchesFilter;
                  }).toList();
                  _exportToPDF(list);
                }
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(), 
        backgroundColor: const Color(0xFFD946EF), 
        child: const Icon(Icons.add, color: Colors.white)
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search name or class...", 
                prefixIcon: const Icon(Icons.search, color: Colors.grey), 
                filled: true, fillColor: const Color(0xFF1E1E1E), 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ["All", "IPA", "IPS"].map((f) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(f),
                selected: _selectedFilter == f,
                onSelected: (v) => setState(() => _selectedFilter = f),
                selectedColor: const Color(0xFFD946EF),
                backgroundColor: const Color(0xFF1E1E1E),
                labelStyle: TextStyle(color: _selectedFilter == f ? Colors.white : Colors.grey),
              ),
            )).toList(),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.getStudents(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs.where((doc) {
                  var d = doc.data() as Map<String, dynamic>;
                  bool matchesSearch = d['name'].toString().toLowerCase().contains(_searchQuery);
                  bool matchesFilter = _selectedFilter == "All" || d['class'].toString().contains(_selectedFilter);
                  return matchesSearch && matchesFilter;
                }).toList();

                if (docs.isEmpty) return const Center(child: Text("No students found.", style: TextStyle(color: Colors.grey)));

                return ListView.builder(
                  itemCount: docs.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    var d = docs[index].data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E), 
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05))
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.cyanAccent.withValues(alpha: 0.1), 
                          child: const Icon(Icons.person, color: Colors.cyanAccent)
                        ),
                        title: Text(d['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text("${d['class']} • ${d['age']} Thn", style: const TextStyle(color: Colors.grey)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => _showFormDialog(id: docs[index].id, data: d)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _db.deleteStudent(docs[index].id)),
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