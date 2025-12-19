import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart'; // Library untuk ambil file
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

  // Helper: Upload File ke Firebase Storage
  Future<String?> uploadFile(PlatformFile file, String studentName) async {
    try {
      // Buat nama file unik: documents/nama_siswa/nama_file
      final path = 'documents/$studentName/${file.name}';
      final fileBytes = file.bytes; // Untuk Web/Mobile support modern
      final filePath = file.path; // Untuk Mobile legacy

      final ref = FirebaseStorage.instance.ref().child(path);

      if (fileBytes != null) {
        await ref.putData(fileBytes);
      } else if (filePath != null) {
        await ref.putFile(File(filePath));
      }

      return await ref.getDownloadURL(); // Kembalikan Link Foto
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Upload Failed: $e"), backgroundColor: Colors.red));
      return null;
    }
  }

  // Fungsi Form Dialog (Add / Edit + Upload)
  void _showFormDialog({String? id, Map<String, dynamic>? data}) {
    final nameCtrl = TextEditingController(text: data?['name'] ?? '');
    final classCtrl = TextEditingController(text: data?['class'] ?? '');
    final ageCtrl = TextEditingController(text: data?['age']?.toString() ?? '');

    // Map untuk menampung dokumen yang sudah ada atau baru
    Map<String, dynamic> currentDocs = data?['documents'] != null
        ? Map<String, dynamic>.from(data!['documents'])
        : {};

    bool isEdit = id != null;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
          // StatefulBuilder biar loading upload jalan realtime di dialog
          builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? "Update Student Data" : "Add New Student",
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 20),

                CustomTextField(
                    controller: nameCtrl,
                    hint: "Full Name",
                    icon: Icons.person),
                const SizedBox(height: 12),
                CustomTextField(
                    controller: classCtrl,
                    hint: "Class (e.g. 12 IPA)",
                    icon: Icons.class_),
                const SizedBox(height: 12),
                CustomTextField(
                    controller: ageCtrl,
                    hint: "Age",
                    icon: Icons.cake,
                    type: TextInputType.number),

                const SizedBox(height: 24),

                // --- BAGIAN UPLOAD FILE (Hanya muncul saat Edit) ---
                if (isEdit) ...[
                  const Text("Student Documents (KK, SPP, Etc)",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  // List Dokumen yang sudah diupload
                  Wrap(
                    spacing: 8,
                    children: currentDocs.entries.map((entry) {
                      return Chip(
                        label: Text(entry.key,
                            style: const TextStyle(fontSize: 10)),
                        backgroundColor: Colors.grey[900],
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () {
                          setModalState(() => currentDocs.remove(entry.key));
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 10),

                  // Tombol Upload
                  isUploading
                      ? const Center(
                          child:
                              LinearProgressIndicator(color: Color(0xFFD946EF)))
                      : OutlinedButton.icon(
                          onPressed: () async {
                            // Pilih File
                            FilePickerResult? result =
                                await FilePicker.platform.pickFiles();
                            if (result != null) {
                              setModalState(() => isUploading = true);

                              // Proses Upload ke Firebase
                              String? url = await uploadFile(
                                  result.files.single, nameCtrl.text);

                              if (url != null) {
                                // Simpan nama file dan URL-nya
                                currentDocs[result.files.single.name] = url;
                              }
                              setModalState(() => isUploading = false);
                            }
                          },
                          icon: const Icon(Icons.upload_file,
                              color: Color(0xFFD946EF)),
                          label: const Text("Upload Document / Photo",
                              style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFD946EF)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20))),
                        ),
                  const SizedBox(height: 24),
                ],

                // Tombol Simpan
                NeonButton(
                  text: isEdit ? "Update Data" : "Save Student",
                  onPressed: isUploading
                      ? () {}
                      : () {
                          if (isEdit) {
                            _db.updateStudent(id, nameCtrl.text, classCtrl.text,
                                int.parse(ageCtrl.text), currentDocs);
                          } else {
                            _db.addStudent(nameCtrl.text, classCtrl.text,
                                int.parse(ageCtrl.text));
                          }
                          Navigator.pop(context);
                        },
                )
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Students Data"),
          backgroundColor: Colors.transparent),
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
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search student name...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.getStudents(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                var students = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return data['name']
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery);
                }).toList();

                if (students.isEmpty)
                  return const Center(
                      child: Text("No students found.",
                          style: TextStyle(color: Colors.grey)));

                return ListView.builder(
                  itemCount: students.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    var data = students[index].data() as Map<String, dynamic>;
                    String id = students[index].id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                            backgroundColor: Colors.grey[900],
                            child:
                                const Icon(Icons.person, color: Colors.white)),
                        title: Text(data['name'],
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "${data['class']} • ${data['age']} Years Old",
                            style: const TextStyle(color: Colors.grey)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.blueAccent),
                              onPressed: () =>
                                  _showFormDialog(id: id, data: data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent),
                              onPressed: () => _db.deleteStudent(id),
                            ),
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
