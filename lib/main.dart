import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/scheduler.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Task Manager',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: const Color.fromARGB(201, 17, 139, 221)),
      ),
      home: const MyHomePage(title: 'My Tasks'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: FutureBuilder(
        future: FirebaseFirestore.instance.collection('tasks').get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Something went wrong');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final tasks = snapshot.data!.docs;

          if (tasks.isEmpty) {
            return const Center(
              child: Text('No tasks found'),
            );
          }
          return ListView(
            children: tasks.map((doc) {
              final data = doc.data();
              return ListTile(
                title: Text(data['title'] ?? 'Untitled Task'),
                subtitle: Text('priority: ${data['priority'] ?? '-'}'),

                leading: Checkbox(
                  value: data['completed'] ?? false,
                  onChanged: null,
                ),
              );
            }).toList(),
          );
        }
      ),
    );
  }
}
