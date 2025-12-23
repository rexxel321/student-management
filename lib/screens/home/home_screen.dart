import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart
import '../students/student_list_screen.dart';
import '../teachers/teacher_list_screen.dart';
import '../../services/database_service.dart';
import '../students/extracurricular_screen.dart';
import '../students/facility_screen.dart';

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
      body: StreamBuilder<QuerySnapshot>(
        // Ambil data siswa untuk seluruh dashboard agar sinkron
        stream: db.getStudents(),
        builder: (context, studentSnapshot) {
          // Logika Perhitungan Statistik Siswa
          var studentDocs = studentSnapshot.data?.docs ?? [];
          int totalStudents = studentDocs.length;
          
          // Hitung Siswa per Jurusan
          int ipaCount = studentDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['class'].toString().contains('IPA');
          }).length;
          
          int ipsCount = studentDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['class'].toString().contains('IPS');
          }).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SECTION 1: FINANCIAL OVERVIEW (Total Gaji) ---
                StreamBuilder<QuerySnapshot>(
                  stream: db.getTeachers(),
                  builder: (context, teacherSnapshot) {
                    double totalSalary = 0;
                    int teacherCount = 0;

                    if (teacherSnapshot.hasData) {
                      teacherCount = teacherSnapshot.data!.docs.length;
                      for (var doc in teacherSnapshot.data!.docs) {
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
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text(formatCurrency(totalSalary),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
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
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // --- SECTION 2: DISTRIBUTION CHART (Pie Chart) ---
                const Text("Student Distribution",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 16),
                Container(
                  height: 220,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: totalStudents == 0 
                    ? const Center(child: Text("No Data Available", style: TextStyle(color: Colors.grey)))
                    : PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          value: ipaCount.toDouble(),
                          title: 'IPA\n$ipaCount',
                          color: Colors.blue,
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          value: ipsCount.toDouble(),
                          title: 'IPS\n$ipsCount',
                          color: const Color(0xFFD946EF),
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- SECTION 3: QUICK STATS ---
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard("Total Students", totalStudents.toString(),
                          Icons.people, Colors.blue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                          "Total Classes", "14", Icons.class_, Colors.orange),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // --- SECTION 4: MENU ACTIONS ---
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
                _buildMenuTile(
                    context,
                    "Extracurricular",
                    "Manage sports, arts, and clubs",
                    Icons.emoji_events_outlined,
                    Colors.orangeAccent,
                     ExtraScreen(), // <-- Arahkan ke class ExtraScreen tadi
                  ),

                _buildMenuTile(
                    context,
                    "Facility Log",
                    "Cleaning status & OB reports",
                    Icons.cleaning_services_outlined,
                    Colors.greenAccent,
                    FacilityScreen(),
                  ),



                const SizedBox(height: 24),

                // --- SECTION 5: LIVE SCHOOL CAPACITY (Dinamis) ---
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
                      const Text("Live School Capacity",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 20),
                      // Target per jurusan misal 50 orang
                      _buildProgressBar("Science Class (IPA)", ipaCount / 50, Colors.blue),
                      const SizedBox(height: 16),
                      _buildProgressBar("Social Class (IPS)", ipsCount / 50, const Color(0xFFD946EF)),
                    ],
                  ),
                )
              ],
            ),
          );
        },
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

  // Widget Grafik Batang Dinamis
  Widget _buildProgressBar(String label, double percent, Color color) {
    // Pastikan percent tidak lebih dari 1.0 (100%)
    double safePercent = percent > 1.0 ? 1.0 : percent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Text("${(safePercent * 100).toInt()}%",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: safePercent,
            minHeight: 8,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}