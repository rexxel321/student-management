import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../students/student_list_screen.dart';
import '../teachers/teacher_list_screen.dart';
import '../../services/database_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Helper untuk format duit
  String formatCurrency(double amount) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Admin Dashboard",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text("School Performance Overview",
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: FINANCIAL OVERVIEW (Total Gaji) ---
            StreamBuilder<QuerySnapshot>(
              stream: db.getTeachers(),
              builder: (context, snapshot) {
                double totalSalary = 0;
                int teacherCount = 0;

                if (snapshot.hasData) {
                  teacherCount = snapshot.data!.docs.length;
                  for (var doc in snapshot.data!.docs) {
                    totalSalary += (doc['salary'] as num).toDouble();
                  }
                }

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFD946EF), Color(0xFF8B5CF6)]),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFD946EF).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Total Monthly Salary Expense",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(formatCurrency(totalSalary),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(20)),
                            child: Text("Active Teachers: $teacherCount",
                                style: const TextStyle(color: Colors.white)),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // --- SECTION 2: STATS GRID ---
            const Text("Quick Stats",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 16),

            Row(
              children: [
                // Card Siswa
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: db.getStudents(),
                    builder: (context, snapshot) {
                      int count =
                          snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return _buildStatCard("Total Students", count.toString(),
                          Icons.people, Colors.blue);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Card Kelas (Dummy static for now, or you can count distinct classes later)
                Expanded(
                    child: _buildStatCard(
                        "Total Classes", "12", Icons.class_, Colors.orange)),
              ],
            ),

            const SizedBox(height: 24),

            // --- SECTION 3: MENU ACTIONS ---
            const Text("Manage Data",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 16),

            _buildMenuTile(
                context,
                "Manage Students",
                "Edit, Add & Delete Students",
                Icons.person_outline,
                Colors.blue,
                const StudentListScreen()),
            const SizedBox(height: 12),
            _buildMenuTile(
                context,
                "Manage Teachers",
                "Edit Salaries & Subjects",
                Icons.school_outlined,
                const Color(0xFFD946EF),
                const TeacherListScreen()),

            const SizedBox(height: 24),

            // --- SECTION 4: SCHOOL CAPACITY (Grafik Batang Sederhana) ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("School Capacity",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 20),
                  _buildProgressBar("Science Class (IPA)", 0.8, Colors.blue),
                  const SizedBox(height: 16),
                  _buildProgressBar("Social Class (IPS)", 0.65, Colors.purple),
                  const SizedBox(height: 16),
                  _buildProgressBar("Language Class", 0.4, Colors.green),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // Widget Kartu Statistik Kecil
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  // Widget Menu Panjang
  Widget _buildMenuTile(BuildContext context, String title, String subtitle,
      IconData icon, Color color, Widget page) {
    return ListTile(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      contentPadding: const EdgeInsets.all(16),
      tileColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white10)),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color),
      ),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing:
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
    );
  }

  // Widget Grafik Batang (Tanpa Library Berat)
  Widget _buildProgressBar(String label, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Text("${(percent * 100).toInt()}%",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
