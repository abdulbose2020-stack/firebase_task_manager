import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _taskService = TaskService();
  final _authService = AuthService();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _tasksStream;

  String _selectedFilter = 'All';
  final List<Task> _additionalTasks = [];
  bool _isLoadingMore = false;
  bool _hasMoreTasks = true;
  QueryDocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final _userService = UserService();
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _tasksStream = _taskService.watchFirstTaskPage();
    _loadProfile();
  }

  String _priorityLabel(int priority) {
    switch (priority) {
      case 3:
        return 'High';
      case 2:
        return 'Medium';
      default:
        return 'Low';
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not log out. Please try again.')),
      );
    }
  }

  Future<void> _pickProfileImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _loadProfile() async {
    try {
      final snapshot = await _userService.getProfile();

      if (!mounted || !snapshot.exists) return;

      final data = snapshot.data();

      if (data != null) {
        setState(() {
          _displayName = data['displayName'] as String? ?? '';
        });
      }
    } catch (e) {
      debugPrint('Could not load profile: $e');
    }
  }

  Future<void> _saveProfile(String dispalyName) async {
    try {
      await _userService.saveProfile(
        displayName: dispalyName,
        profileImageUrl: null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile save successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save profile: $e')));
    }
  }

  Future<void> _showEditProfileDialog() async {
    final controller = TextEditingController();

    try {
      final displayName = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Edit profile'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Display name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.of(dialogContext).pop(name);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (displayName == null || displayName.isEmpty || !mounted) {
        return;
      }

      await _saveProfile(displayName);
    } finally {
      controller.dispose();
    }
  }

  Future<void> _sendVerificationEmail() async {
    try {
      await _authService.sendEmailVerification();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent. Check your inbox.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send verification email: $e')),
      );
    }
  }

  Future<void> _refreshEmailVerification() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _authService.isEmailVerified
                ? 'Your email is verified!'
                : 'Email is not verified yet. Open the link in your inbox, then try again.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not check verification status: $e')),
      );
    }
  }

  Future<void> _addTask() async {
    var enteredTitle = '';
    var selectedPriority = 2;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                onChanged: (value) => enteredTitle = value,
                decoration: const InputDecoration(hintText: 'Enter task title'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 3, child: Text('High')),
                  DropdownMenuItem(value: 2, child: Text('Medium')),
                  DropdownMenuItem(value: 1, child: Text('Low')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedPriority = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, {
                  'title': enteredTitle.trim(),
                  'priority': selectedPriority,
                });
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    final title = result['title'] as String;
    final priority = result['priority'] as int;

    if (title.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title.')),
      );
      return;
    }

    try {
      await _taskService.addTask(title, priority: priority);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task added')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not add task: $e')));
    }
  }

  Future<void> _editTask(Task task) async {
    var editedTitle = task.title;
    var selectedPriority = task.priority;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: task.title,
                autofocus: true,
                onChanged: (value) => editedTitle = value,
                decoration: const InputDecoration(hintText: 'Enter task title'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 3, child: Text('High')),
                  DropdownMenuItem(value: 2, child: Text('Medium')),
                  DropdownMenuItem(value: 1, child: Text('Low')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedPriority = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, {
                  'title': editedTitle.trim(),
                  'priority': selectedPriority,
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    final title = result['title'] as String;
    final priority = result['priority'] as int;

    if (title.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task title cannot be empty.')),
      );
      return;
    }

    try {
      await _taskService.updateTask(task.id, title: title, priority: priority);

      if (!mounted) return;

      setState(() {
        final index = _additionalTasks.indexWhere((item) => item.id == task.id);

        if (index != -1) {
          final currentTask = _additionalTasks[index];

          _additionalTasks[index] = Task(
            id: currentTask.id,
            title: title,
            completed: currentTask.completed,
            priority: priority,
          );
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task updated')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not edit task: $e')));
    }
  }

  Future<void> _toggleTask(Task task, bool completed) async {
    try {
      await _taskService.updateTask(task.id, completed: completed);

      if (!mounted) return;

      setState(() {
        final index = _additionalTasks.indexWhere((item) => item.id == task.id);

        if (index != -1) {
          _additionalTasks[index] = Task(
            id: task.id,
            title: task.title,
            completed: completed,
            priority: task.priority,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update task: $e')));
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task?'),
        content: Text('Delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _taskService.deleteTask(task.id);

      if (!mounted) return;

      setState(() {
        _additionalTasks.removeWhere((item) => item.id == task.id);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task deleted')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete task: $e')));
    }
  }

  Future<void> _loadMoreTasks() async {
    if (_isLoadingMore || !_hasMoreTasks || _lastDocument == null) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final snapshot = await _taskService.getNextTaskPage(_lastDocument!);

      if (!mounted) return;

      setState(() {
        if (snapshot.docs.isNotEmpty) {
          final existingIds = _additionalTasks.map((task) => task.id).toSet();

          for (final doc in snapshot.docs) {
            if (existingIds.add(doc.id)) {
              _additionalTasks.add(Task.fromMap(doc.data(), doc.id));
            }
          }

          _lastDocument = snapshot.docs.last;
        }

        _hasMoreTasks = snapshot.docs.length == 10;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load more tasks: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Widget _buildLoadMoreButton() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextButton(
          onPressed: _hasMoreTasks ? _loadMoreTasks : null,
          child: const Text('Load More Tasks'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _displayName.isEmpty ? 'My Tasks' : 'Hello, $_displayName',
        ),
        actions: [
          IconButton(
            onPressed: _pickProfileImage,
            tooltip: 'Choose profile image',
            icon: CircleAvatar(
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : null,
              child: _profileImage == null ? const Icon(Icons.person) : null,
            ),
          ),

          IconButton(
            onPressed: _showEditProfileDialog,
            tooltip: 'Edit profile',
            icon: const Icon(Icons.edit),
          ),

          IconButton(
            onPressed: _logout,
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_authService.isEmailVerified)
            Card(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Please verify your email address.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Check your inbox for the verification link. If you cannot find it, check your spam folder.',
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ElevatedButton(
                          onPressed: _sendVerificationEmail,
                          child: const Text('Send verification email'),
                        ),
                        TextButton(
                          onPressed: _refreshEmailVerification,
                          child: const Text("I've verified"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: ['All', 'Pending', 'Completed'].map((filter) {
                return ChoiceChip(
                  label: Text(filter),
                  selected: _selectedFilter == filter,
                  showCheckmark: false,
                  onSelected: (_) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _tasksStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Something went wrong loading tasks.'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return const Center(child: Text('No tasks available.'));
                }

                final documents = snapshot.data!.docs;

                // Set the pagination cursor from the first page.
                if (_additionalTasks.isEmpty) {
                  _lastDocument = documents.isEmpty ? null : documents.last;
                  _hasMoreTasks = documents.length == 10;
                }

                final firstPageTasks = documents.map(
                  (doc) => Task.fromMap(doc.data(), doc.id),
                );

                // Merge pages while avoiding duplicate task IDs.
                final uniqueTasks = <String, Task>{};

                for (final task in [...firstPageTasks, ..._additionalTasks]) {
                  uniqueTasks[task.id] = task;
                }

                final allTasks = uniqueTasks.values.toList();

                final tasks = allTasks.where((task) {
                  if (_selectedFilter == 'Pending') {
                    return !task.completed;
                  }

                  if (_selectedFilter == 'Completed') {
                    return task.completed;
                  }

                  return true;
                }).toList();

                if (tasks.isEmpty) {
                  final message = switch (_selectedFilter) {
                    'Pending' => 'No pending tasks on loaded pages.',
                    'Completed' => 'No completed tasks on loaded pages.',
                    _ => 'No tasks yet. Tap + to add one!',
                  };

                  return ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(child: Text(message)),
                      if (_hasMoreTasks) _buildLoadMoreButton(),
                    ],
                  );
                }

                return ListView.builder(
                  itemCount: tasks.length + (_hasMoreTasks ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == tasks.length) {
                      return _buildLoadMoreButton();
                    }

                    final task = tasks[index];

                    return ListTile(
                      leading: Checkbox(
                        value: task.completed,
                        onChanged: (value) {
                          if (value != null) {
                            _toggleTask(task, value);
                          }
                        },
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      subtitle: Text(
                        'Priority: ${_priorityLabel(task.priority)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Edit task',
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editTask(task),
                          ),
                          IconButton(
                            tooltip: 'Delete task',
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteTask(task),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        tooltip: 'Add task',
        child: const Icon(Icons.add),
      ),
    );
  }
}
