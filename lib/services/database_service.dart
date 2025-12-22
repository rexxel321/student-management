import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================
  // 🎓 STUDENTS MANAGEMENT
  // ==========================

  // 1. GET (Ambil Data)
  Stream<QuerySnapshot> getStudents() {
    return _db
        .collection('students')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 2. ADD (Tambah Data Baru)
  Future<void> addStudent(String name, String studentClass, int age) async {
    await _db.collection('students').add({
      'name': name,
      'class': studentClass,
      'age': age,
      'documents': {}, // Inisialisasi map kosong agar tidak error saat dibaca
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 3. UPDATE (Edit Data + Simpan Link Dokumen)
  // 👉 Parameter 'documents' ditambahkan di sini
  Future<void> updateStudent(String id, String name, String studentClass,
      int age, Map<String, dynamic> documents) async {
    await _db.collection('students').doc(id).update({
      'name': name,
      'class': studentClass,
      'age': age,
      'documents':
          documents, // Update field documents dengan Map terbaru (Link File)
    });
  }

  // 4. DELETE (Hapus Data)
  Future<void> deleteStudent(String id) async {
    await _db.collection('students').doc(id).delete();
  }

  // ==========================
  // 👨‍🏫 TEACHERS MANAGEMENT
  // ==========================

  Stream<QuerySnapshot> getTeachers() {
    return _db
        .collection('teachers')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addTeacher(String name, String subject, double salary) async {
    await _db.collection('teachers').add({
      'name': name,
      'subject': subject,
      'salary': salary,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTeacher(
      String id, String name, String subject, double salary) async {
    await _db.collection('teachers').doc(id).update({
      'name': name,
      'subject': subject,
      'salary': salary,
    });
  }

  Future<void> deleteTeacher(String id) async {
    await _db.collection('teachers').doc(id).delete();
  }
}
