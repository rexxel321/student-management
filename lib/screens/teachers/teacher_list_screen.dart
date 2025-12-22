import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_widgets.dart';

class TeacherListScreen extends StatefulWidget {
  const TeacherListScreen({super.key});

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  final DatabaseService _db = DatabaseService();
  String _searchQuery = ""; // Variabel untuk pencarian

  final List<String> _subjects = [
    'Math', 'Physics', 'Biology', 'Chemistry', 'English',
    'History', 'Geography', 'Art', 'Informatics',
    'Economics', 'Indonesia Language', 'PPKn',
  ];

  String formatRupiah(double salary) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(salary);
  }

  // --- FITUR EXPORT PDF KHUSUS GURU ---
  Future<void> _exportToPDF(List<QueryDocumentSnapshot> teachers) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pdfContext) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Laporan Data Guru", 
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text("Total Guru: ${teachers.length}"),
              pw.Text("Tanggal Cetak: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}"),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Nama', 'Mata Pelajaran', 'Gaji'],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                data: teachers.map((t) {
                  final data = t.data() as Map<String, dynamic>;
                  return [
                    data['name'] ?? '-',
                    data['subject'] ?? '-',
                    formatRupiah((data['salary'] ?? 0).toDouble())
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
      name: 'Laporan_Guru.pdf'
    );
  }

  void _showAddTeacherDialog() {
    final nameCtrl = TextEditingController();
    final salaryCtrl = TextEditingController();
    String? selectedSubject;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
            child: SingleChildScrollView(
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
                      controller: nameCtrl, 
                      hint: "Teacher Name", 
                      icon: Icons.person),
                  const SizedBox(height: 16),

                  const Text("Subject", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.book, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                    hint: const Text("Select Subject", style: TextStyle(color: Colors.grey)),
                    value: selectedSubject,
                    items: _subjects.map((String sub) {
                      return DropdownMenuItem<String>(
                        value: sub,
                        child: Text(sub),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setModalState(() {
                        selectedSubject = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  const Text("Salary", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: salaryCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.monetization_on, color: Colors.grey),
                      hintText: "Salary (e.g. 5000000)",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  NeonButton(
                    text: "Save Teacher",
                    onPressed: () {
                      if (nameCtrl.text.isNotEmpty && 
                          salaryCtrl.text.isNotEmpty && 
                          selectedSubject != null) {
                        
                        _db.addTeacher(
                          nameCtrl.text,
                          selectedSubject!,
                          double.parse(salaryCtrl.text),
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please fill all fields!"))
                        );
                      }
                    },
                  )
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Teachers Management", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Tombol PDF dinamis mengikuti data yang terfilter
          StreamBuilder<QuerySnapshot>(
            stream: _db.getTeachers(),
            builder: (context, snapshot) {
              return IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                onPressed: () {
                  if (snapshot.hasData) {
                    var teachers = snapshot.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return data['name'].toString().toLowerCase().contains(_searchQuery);
                    }).toList();
                    _exportToPDF(teachers);
                  }
                },
              );
            }
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTeacherDialog,
        backgroundColor: const Color(0xFFD946EF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar untuk Guru
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search teacher name...",
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
              stream: _db.getTeachers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var teachers = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return data['name'].toString().toLowerCase().contains(_searchQuery);
                }).toList();

                if (teachers.isEmpty) {
                  return const Center(
                      child: Text("No teachers found.",
                          style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: teachers.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.school, color: Color(0xFF8B5CF6)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(data['subject'] ?? '-',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(formatRupiah((data['salary'] ?? 0).toDouble()),
                                    style: const TextStyle(
                                        color: Color(0xFFD946EF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _db.deleteTeacher(id),
                          ),
                        ],
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