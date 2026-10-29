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

  Stream<List<Task>> getTasks() {
    return _task
        .where('ownerId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Task.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Query<Map<String, dynamic>> _buildTaskQuery({
    bool? completed,
  }) {
    Query<Map<String, dynamic>> query =
        _task.where('ownerId', isEqualTo: _userId);

    if (completed != null) {
      query = query.where('completed', isEqualTo: completed);
    }

    return query.orderBy('createdAt', descending: true);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchFirstTaskPage({
    bool? completed,
  }) {
    return _buildTaskQuery(completed: completed)
        .limit(10)
        .snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getFirstTaskPage({
    bool? completed,
  }) {
    return _buildTaskQuery(completed: completed).limit(10).get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getNextTaskPage(
    QueryDocumentSnapshot<Map<String, dynamic>> lastDocument, {
    bool? completed,
  }) {
    return _buildTaskQuery(completed: completed)
        .startAfterDocument(lastDocument)
        .limit(10)
        .get();
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

  Future<void> completeTaskSafely(String id) async {
    final taskRef = _task.doc(id);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(taskRef);

      if (!snapshot.exists) {
        throw Exception('Task not found');
      }

      final data = snapshot.data()!;
      final isCompleted = data['completed'] as bool? ?? false;

      if (isCompleted) return;

      transaction.update(taskRef, {
        'completed': true,
      });
    });
  }

  Future<void> deleteTask(String id) async {
    await _task.doc(id).delete();
  }
}
