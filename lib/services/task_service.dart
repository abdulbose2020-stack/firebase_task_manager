import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';

class TaskService {
  final CollectionReference<Map<String, dynamic>> _task =
      FirebaseFirestore.instance.collection('tasks');

  String get _userId => FirebaseAuth.instance.currentUser!.uid;

  Future<void> addTask(
    String title, {
    required int priority,
  }) async {
    await _task.add({
      'ownerId': _userId,
      'title': title,
      'completed': false,
      'priority': priority,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Task>> getTasks() async {
    final snapshot = await _task
        .where('ownerId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return Task.fromMap(doc.data(), doc.id);
    }).toList();
  }

  Future<void> updateTask(
    String id, {
    String? title,
    bool? completed,
    int? priority,
  }) async {
    final updates = <String, dynamic>{};

    if (title != null) updates['title'] = title;
    if (completed != null) updates['completed'] = completed;
    if (priority != null) updates['priority'] = priority;

    if (updates.isEmpty) return;

    await _task.doc(id).update(updates);
  }

  Future<void> deleteTask(String id) async {
    await _task.doc(id).delete();
  }
}
