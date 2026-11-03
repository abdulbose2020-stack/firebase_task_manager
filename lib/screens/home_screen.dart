import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_task_manager/providers/task_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import '../widgets/task_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _userService = UserService();
  final _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  File? _profileImage;
  String _displayName = '';
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
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

    if (pickedFile == null || !mounted) return;

    final imageFile = File(pickedFile.path);

    setState(() {
      _profileImage = imageFile;
    });

    try {
      final imageUrl = await _storageService.uploadProfileImage(
        userId: FirebaseAuth.instance.currentUser!.uid,
        imageFile: imageFile,
      );

      await _userService.saveProfile(
        displayName: _displayName,
        profileImageUrl: imageUrl,
      );

      if (!mounted) return;

      setState(() {
        _profileImageUrl = imageUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image saved successfully!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save profile image. Please try again.'),
        ),
      );
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
          _profileImageUrl = data['profileImageUrl'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Could not load profile: $e');
    }
  }

  Future<void> _saveProfile(String displayName) async {
    try {
      await _userService.saveProfile(
        displayName: displayName,
        profileImageUrl: null,
      );

      if (!mounted) return;

      setState(() {
        _displayName = displayName;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save profile. Please try again.'),
        ),
      );
    }
  }

  Future<void> _showEditProfileDialog() async {
    final controller = TextEditingController(text: _displayName);

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
        const SnackBar(
          content: Text('Could not send verification email. Please try again.'),
        ),
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
        const SnackBar(
          content: Text(
            'Could not check verification status. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _addTask() async {
    final formKey = GlobalKey<FormState>();
    var enteredTitle = '';
    var selectedPriority = 2;
    var isSaving = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Task'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  autofocus: true,
                  onChanged: (value) => enteredTitle = value,
                  decoration: const InputDecoration(
                    hintText: 'Enter task title',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a task title.';
                    }

                    return null;
                  },
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
                  onChanged: isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedPriority = value;
                            });
                          }
                        },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setDialogState(() {
                        isSaving = true;
                      });

                      final provider = context.read<TaskProvider>();

                      final success = await provider.addTask(
                        enteredTitle.trim(),
                        priority: selectedPriority,
                      );

                      if (!dialogContext.mounted) return;

                      if (success) {
                        Navigator.pop(dialogContext, true);
                      } else {
                        setDialogState(() {
                          isSaving = false;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              provider.errorMessage ?? 'Could not add task.',
                            ),
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != true || !mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task added successfully.')));
  }

  Future<void> _editTask(Task task) async {
    final formKey = GlobalKey<FormState>();
    var editedTitle = task.title;
    var selectedPriority = task.priority;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Task'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: task.title,
                  autofocus: true,
                  onChanged: (value) => editedTitle = value,
                  decoration: const InputDecoration(
                    hintText: 'Enter task title',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Task title cannot be empty.';
                    }

                    return null;
                  },
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

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

    if (result == null || !mounted) return;

    final title = result['title'] as String;
    final priority = result['priority'] as int;
    final provider = context.read<TaskProvider>();

    final success = await provider.updateTask(
      task.id,
      title: title,
      priority: priority,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Could not update task.'),
        ),
      );

      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task updated successfully.')));
  }

  Future<void> _toggleTask(Task task, bool completed) async {
    final provider = context.read<TaskProvider>();

    final success = await provider.toggleTask(task.id, completed);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Could not update task.'),
        ),
      );
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

    if (confirmed != true || !mounted) return;

    final provider = context.read<TaskProvider>();

    final success = await provider.deleteTask(task.id);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Could not delete task.'),
        ),
      );

      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task deleted.')));
  }

  Widget _buildLoadMoreButton(TaskProvider provider) {
    if (provider.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextButton(
          onPressed: provider.hasMoreTasks ? provider.loadMoreTasks : null,
          child: const Text('Load More Tasks'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final selectedFilter = provider.selectedFilter;

    return Scaffold(
      appBar: AppBar(
        title: Text(_displayName.isEmpty ? 'My Tasks' : 'Hello, $_displayName'),
        actions: [
          IconButton(
            onPressed: _pickProfileImage,
            tooltip: 'Choose profile image',
            icon: CircleAvatar(
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                  ? NetworkImage(_profileImageUrl!)
                  : null,
              child:
                  _profileImage == null &&
                      (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                  ? const Icon(Icons.person)
                  : null,
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
                      'Check your inbox for the verification link. '
                      'If you cannot find it, check your spam folder.',
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
                  selected: selectedFilter == filter,
                  showCheckmark: false,
                  onSelected: (_) {
                    provider.changeFilter(filter);
                  },
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.hasStreamError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Something went wrong loading tasks.'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: provider.retryTasksStream,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final tasks = provider.tasks;

                if (tasks.isEmpty) {
                  final message = switch (selectedFilter) {
                    'Pending' => 'No pending tasks.',
                    'Completed' => 'No completed tasks.',
                    _ => 'No tasks yet. Tap + to add one!',
                  };

                  return ListView(
                    children: [
                      const SizedBox(height: 80),
                      Center(child: Text(message)),
                      if (provider.hasMoreTasks) _buildLoadMoreButton(provider),
                    ],
                  );
                }

                return ListView.builder(
                  itemCount: tasks.length + (provider.hasMoreTasks ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == tasks.length) {
                      return _buildLoadMoreButton(provider);
                    }

                    final task = tasks[index];

                    return TaskTile(
                      task: task,
                      priorityLabel: _priorityLabel(task.priority),
                      onToggle: (value) => _toggleTask(task, value),
                      onEdit: () => _editTask(task),
                      onDelete: () => _deleteTask(task),
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
