import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_widgets.dart';

class ExtraScreen extends StatefulWidget {
  const ExtraScreen({super.key});

  @override
  State<ExtraScreen> createState() => _ExtraScreenState();
}

class _ExtraScreenState extends State<ExtraScreen> {
  final DatabaseService _db = DatabaseService();
  
  // Variabel penampung input dinamis
  String? selectedDay;
  TimeOfDay? selectedTime;

  // List hari untuk Dropdown
  final List<String> _days = [
    "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
  ];

  // Fungsi popup tambah ekskul dengan Picker
  void _showAddExtraDialog() {
    final nameCtrl = TextEditingController();
    final coachCtrl = TextEditingController();

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
                  const Text("Add New Activity",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 20),
                  
                  // Input Nama Eskul
                  CustomTextField(
                      controller: nameCtrl, 
                      hint: "Eskul Name (e.g. Basket)", 
                      icon: Icons.emoji_events),
                  const SizedBox(height: 16),
                  
                  // Input Nama Pembina
                  CustomTextField(
                      controller: coachCtrl, 
                      hint: "Coach Name", 
                      icon: Icons.person_outline),
                  const SizedBox(height: 20),

                  const Text("Schedule (Day & Time)", 
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),

                  // Row untuk Dropdown Hari dan Button Jam
                  Row(
                    children: [
                      // Dropdown Pilih Hari
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedDay,
                              hint: const Text("Day", style: TextStyle(color: Colors.grey, fontSize: 14)),
                              isExpanded: true,
                              dropdownColor: const Color(0xFF1E1E1E),
                              style: const TextStyle(color: Colors.white),
                              items: _days.map((day) => DropdownMenuItem(
                                value: day,
                                child: Text(day),
                              )).toList(),
                              onChanged: (val) {
                                setModalState(() => selectedDay = val);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Picker Pilih Jam
                      Expanded(
                        flex: 2,
                        child: InkWell(
                          onTap: () async {
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setModalState(() => selectedTime = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  selectedTime == null 
                                    ? "Time" 
                                    : selectedTime!.format(context),
                                  style: TextStyle(
                                    color: selectedTime == null ? Colors.grey : Colors.white,
                                    fontSize: 14
                                  ),
                                ),
                                const Icon(Icons.access_time, color: Colors.orangeAccent, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  
                  // Tombol Simpan
                  NeonButton(
                    text: "Save Activity",
                    onPressed: () async {
                      if (nameCtrl.text.isNotEmpty && selectedDay != null && selectedTime != null) {
                        // Gabungkan data hari dan jam
                        String finalSchedule = "$selectedDay, ${selectedTime!.format(context)}";

                        await FirebaseFirestore.instance.collection('extracurriculars').add({
                          'name': nameCtrl.text,
                          'coach': coachCtrl.text,
                          'schedule': finalSchedule,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        
                        // Reset state local
                        selectedDay = null;
                        selectedTime = null;
                        
                        if (mounted) Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please complete all fields!"))
                        );
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
        title: const Text("Extracurricular Activities", 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExtraDialog,
        backgroundColor: Colors.orangeAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('extracurriculars')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text("No activities found.", 
                style: TextStyle(color: Colors.grey)));
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String id = docs[index].id;

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
                        color: Colors.orangeAccent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emoji_events, color: Colors.orangeAccent),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['name'] ?? '-',
                              style: const TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 16)),
                          const SizedBox(height: 4),
                          Text("Coach: ${data['coach'] ?? '-'}",
                              style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          Text("Schedule: ${data['schedule'] ?? '-'}",
                              style: const TextStyle(
                                  color: Colors.orangeAccent, 
                                  fontSize: 13, 
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => FirebaseFirestore.instance
                          .collection('extracurriculars')
                          .doc(id)
                          .delete(),
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