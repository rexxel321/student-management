import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _selectedClass = "IPA IPA 1";
  DateTime _selectedDate = DateTime.now(); // Default hari ini

  final List<String> _classList = [
    'IPA IPA 1', 'IPA IPA 2', 'IPA IPA 3', 'IPA IPA 4', 'IPA IPA 5', 'IPA IPA 6', 'IPA IPA 7',
    'IPS IPS 1', 'IPS IPS 2', 'IPS IPS 3', 'IPS IPS 4', 'IPS IPS 5', 'IPS IPS 6', 'IPS IPS 7'
  ];

  // Format tanggal untuk ID Database (2023-12-23)
  String get _formattedDate => DateFormat('yyyy-MM-dd').format(_selectedDate);

  // --- FUNGSI UPDATE ABSEN ---
  Future<void> _updateAttendance(String studentId, String name, String status) async {
    final docId = "${studentId}_$_formattedDate";
    await FirebaseFirestore.instance.collection('attendance').doc(docId).set({
      'studentId': studentId,
      'studentName': name,
      'className': _selectedClass,
      'date': _formattedDate,
      'month': DateFormat('yyyy-MM').format(_selectedDate), // Untuk rekap bulanan
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- FUNGSI EXPORT REKAP BULANAN KE PDF ---
  Future<void> _exportMonthlyReport() async {
    String currentMonth = DateFormat('yyyy-MM').format(_selectedDate);
    
    // Ambil data absen bulan ini untuk kelas ini
    var snapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where('className', isEqualTo: _selectedClass)
        .where('month', isEqualTo: currentMonth)
        .get();

    final pdf = pw.Document();
    
    // Logika sederhana: Kelompokkan data berdasarkan nama siswa
    Map<String, Map<String, int>> rekap = {};
    for (var doc in snapshot.docs) {
      var d = doc.data();
      String name = d['studentName'];
      String status = d['status'];
      
      rekap.putIfAbsent(name, () => {'Hadir': 0, 'Izin': 0, 'Alpa': 0});
      rekap[name]![status] = (rekap[name]![status] ?? 0) + 1;
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Laporan Rekap Absensi Bulanan", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text("Kelas: $_selectedClass | Bulan: $currentMonth"),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Nama Siswa', 'Hadir', 'Izin', 'Alpa'],
              data: rekap.entries.map((e) => [
                e.key, 
                e.value['Hadir'].toString(), 
                e.value['Izin'].toString(), 
                e.value['Alpa'].toString()
              ]).toList(),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Rekap_Absen_$_selectedClass.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Absensi Harian", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            onPressed: _exportMonthlyReport,
            tooltip: "Export Rekap Bulan Ini",
          )
        ],
      ),
      body: Column(
        children: [
          // Filter Kelas & Tanggal
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedClass,
                        dropdownColor: Color(0xFF1E1E1E),
                        style: TextStyle(color: Colors.cyanAccent),
                        items: _classList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setState(() => _selectedClass = val!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(DateFormat('dd/MM').format(_selectedDate)),
                )
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('students').where('class', isEqualTo: _selectedClass).snapshots(),
              builder: (context, studentSnapshot) {
                if (!studentSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                var students = studentSnapshot.data!.docs;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('attendance').where('date', isEqualTo: _formattedDate).where('className', isEqualTo: _selectedClass).snapshots(),
                  builder: (context, attendSnapshot) {
                    Map<String, String> attendanceMap = {};
                    if (attendSnapshot.hasData) {
                      for (var doc in attendSnapshot.data!.docs) {
                        attendanceMap[doc['studentId']] = doc['status'];
                      }
                    }

                    return ListView.builder(
                      itemCount: students.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        var student = students[index].data() as Map<String, dynamic>;
                        String sId = students[index].id;
                        String currentStatus = attendanceMap[sId] ?? "Belum Absen";

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _getStatusColor(currentStatus).withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(student['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    Text(currentStatus, style: TextStyle(color: _getStatusColor(currentStatus), fontSize: 11)),
                                  ],
                                ),
                              ),
                              _buildStatusBtn(sId, student['name'], "Hadir", Colors.green),
                              _buildStatusBtn(sId, student['name'], "Izin", Colors.orange),
                              _buildStatusBtn(sId, student['name'], "Alpa", Colors.red),
                            ],
                          ),
                        );
                      },
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

  Widget _buildStatusBtn(String sId, String name, String status, Color color) {
    return IconButton(
      icon: Text(status[0], style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      onPressed: () => _updateAttendance(sId, name, status),
    );
  }

  Color _getStatusColor(String status) {
    if (status == "Hadir") return Colors.green;
    if (status == "Izin") return Colors.orange;
    if (status == "Alpa") return Colors.red;
    return Colors.grey;
  }
}