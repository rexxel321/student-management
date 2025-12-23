import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FacilityScreen extends StatefulWidget {
  const FacilityScreen({super.key});

  @override
  State<FacilityScreen> createState() => _FacilityScreenState();
}

class _FacilityScreenState extends State<FacilityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- FUNGSI CARA 2: AUTO SEED DATA ---
  Future<void> _seedData() async {
    final collection = FirebaseFirestore.instance.collection('facilities');
    
    List<Map<String, dynamic>> dummyData = [
      {'roomName': 'Lab Komputer', 'area': 'Building A', 'status': 'Clean', 'lastCleanedBy': 'Agus', 'time': '07:00 | 23 Dec'},
      {'roomName': 'Kelas 10 IPA 1', 'area': 'Building A', 'status': 'Dirty', 'lastCleanedBy': '-', 'time': '-'},
      {'roomName': 'Perpustakaan', 'area': 'Building B', 'status': 'Clean', 'lastCleanedBy': 'Budi', 'time': '08:30 | 23 Dec'},
      {'roomName': 'Toilet Guru', 'area': 'Building B', 'status': 'Dirty', 'lastCleanedBy': '-', 'time': '-'},
      {'roomName': 'Kantin Utama', 'area': 'Outdoor', 'status': 'Clean', 'lastCleanedBy': 'Siti', 'time': '09:00 | 23 Dec'},
      {'roomName': 'Lapangan Basket', 'area': 'Outdoor', 'status': 'Dirty', 'lastCleanedBy': '-', 'time': '-'},
    ];

    for (var data in dummyData) {
      await collection.add(data);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data Fasilitas Berhasil Ditambahkan!")),
      );
    }
  }

  // --- FUNGSI: HAPUS SEMUA DATA DI AREA TERTENTU ---
  Future<void> _deleteAllInArea(String area) async {
    final collection = FirebaseFirestore.instance.collection('facilities');
    final snapshots = await collection.where('area', isEqualTo: area).get();
    
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Semua data di $area berhasil dihapus")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Facility Monitoring", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Tombol Seed Data
          IconButton(
            icon: const Icon(Icons.cloud_download, color: Color(0xFFD946EF)),
            onPressed: _seedData,
            tooltip: "Isi Data Otomatis",
          ),
          // Tombol Hapus Massal (Berdasarkan Tab yang aktif)
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            onPressed: () {
              String currentArea = _tabController.index == 0 
                  ? "Building A" 
                  : _tabController.index == 1 ? "Building B" : "Outdoor";
              _deleteAllInArea(currentArea);
            },
            tooltip: "Hapus Semua di Area Ini",
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD946EF),
          labelColor: const Color(0xFFD946EF),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.business), text: "Building A"),
            Tab(icon: Icon(Icons.business_center), text: "Building B"),
            Tab(icon: Icon(Icons.park), text: "Outdoor"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFacilityList("Building A"),
          _buildFacilityList("Building B"),
          _buildFacilityList("Outdoor"),
        ],
      ),
    );
  }

  Widget _buildFacilityList(String area) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('facilities')
          .where('area', isEqualTo: area)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_open, color: Colors.grey, size: 64),
                const SizedBox(height: 16),
                Text("No data in $area", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        var docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            String docId = docs[index].id;
            bool isClean = data['status'] == 'Clean';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isClean 
                      ? Colors.green.withValues(alpha: 0.3) 
                      : Colors.redAccent.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isClean 
                              ? Colors.green.withValues(alpha: 0.1) 
                              : Colors.redAccent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isClean ? Icons.check_circle : Icons.warning_amber_rounded,
                          color: isClean ? Colors.green : Colors.redAccent,
                        ),
                      ),
                      title: Text(data['roomName'] ?? 'Unknown Room',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Text(
                        "Last Cleaned: ${data['lastCleanedBy'] ?? 'Never'}\n${data['time'] ?? ''}",
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      // TOMBOL HAPUS SATUAN
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.grey),
                        onPressed: () => FirebaseFirestore.instance.collection('facilities').doc(docId).delete(),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      color: Colors.white.withValues(alpha: 0.03),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isClean ? "Status: Optimal" : "Action Needed!",
                              style: TextStyle(
                                color: isClean ? Colors.green : Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              )),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isClean ? Colors.grey[800] : const Color(0xFFD946EF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              FirebaseFirestore.instance.collection('facilities').doc(docId).update({
                                'status': isClean ? 'Dirty' : 'Clean',
                                'lastCleanedBy': 'OB Team Delta', 
                                'time': DateFormat('HH:mm | dd MMM').format(DateTime.now()),
                              });
                            },
                            icon: Icon(isClean ? Icons.refresh : Icons.cleaning_services, size: 16, color: Colors.white),
                            label: Text(isClean ? "Set Dirty" : "Mark Clean", 
                              style: const TextStyle(fontSize: 12, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}