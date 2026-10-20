
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

class TaskService {
  final CollectionReference<Map<String, dynamic>> _task =
      FirebaseFirestore.instance.collection('tasks');

  Future<void> addTask(String title) async {
    await _task.add({
      'title': title,
      'completed': false,
      'priority': 1,
    });
  }

  Future<List<Task>> getTasks() async {
    final snapshot = await _task.get();

    return snapshot.docs.map((doc) {
      return Task.fromMap(doc.data(), doc.id);
    }).toList();
  }

  Future<void> updateTask(
    String id, {
    String? title,
    bool? completed,
  }) async {
    final updates = <String, dynamic>{};

    if (title != null) updates['title'] = title;
    if (completed != null) updates['completed'] = completed;

    await _task.doc(id).update(updates);
  }

  Future<void> deleteTask(String id) async {
    await _task.doc(id).delete();
  }
}
