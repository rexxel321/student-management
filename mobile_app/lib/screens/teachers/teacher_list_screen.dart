import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Untuk format Rupiah
import '../../services/database_service.dart';
import '../../widgets/custom_widgets.dart';

class TeacherListScreen extends StatefulWidget {
  const TeacherListScreen({super.key});

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  final DatabaseService _db = DatabaseService();

  // Format Rupiah
  String formatRupiah(double salary) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(salary);
  }

  // Fungsi Popup Tambah Guru
  void _showAddTeacherDialog() {
    final nameCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add New Teacher",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 20),
            CustomTextField(
                controller: nameCtrl, hint: "Teacher Name", icon: Icons.person),
            const SizedBox(height: 12),
            CustomTextField(
                controller: subjectCtrl,
                hint: "Subject (e.g. Math)",
                icon: Icons.book),
            const SizedBox(height: 12),
            CustomTextField(
                controller: salaryCtrl,
                hint: "Salary (e.g. 5000000)",
                icon: Icons.monetization_on,
                type: TextInputType.number),
            const SizedBox(height: 24),
            NeonButton(
              text: "Save Teacher",
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && salaryCtrl.text.isNotEmpty) {
                  _db.addTeacher(
                    nameCtrl.text,
                    subjectCtrl.text,
                    double.parse(salaryCtrl.text),
                  );
                  Navigator.pop(context);
                }
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teachers Management"),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTeacherDialog,
        backgroundColor: const Color(0xFFD946EF), // Pink Neon
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.getTeachers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var teachers = snapshot.data!.docs;

          if (teachers.isEmpty) {
            return const Center(
                child: Text("No teachers data yet.",
                    style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            itemCount: teachers.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              var data = teachers[index].data() as Map<String, dynamic>;
              String id = teachers[index].id;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    // Icon Avatar
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6)
                            .withValues(alpha: 0.2), // Fix Deprecated
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school, color: Color(0xFF8B5CF6)),
                    ),
                    const SizedBox(width: 16),
                    // Data Guru
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['name'],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(data['subject'],
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(formatRupiah(data['salary']),
                              style: const TextStyle(
                                  color: Color(0xFFD946EF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                    // Tombol Hapus
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      onPressed: () => _db.deleteTeacher(id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
