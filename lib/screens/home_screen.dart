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
  final Map<String, dynamic> initialProfile;

  const HomeScreen({super.key, this.initialProfile = const {}});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _navy = Color(0xFF172B4D);
  static const Color _background = Color(0xFFF5F7FB);
  static const Color _green = Color(0xFFE1F4E9);

  final _authService = AuthService();
  final _userService = UserService();
  final _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  File? _profileImage;
  String _displayName = '';
  String _username = '';
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();

    _displayName = widget.initialProfile['displayName'] as String? ?? '';

    _username = widget.initialProfile['username'] as String? ?? '';

    _profileImageUrl = widget.initialProfile['profileImageUrl'] as String?;
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm logout'),
        content: const Text('Do you want to logout?'),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('No'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Yes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

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

  Future<void> _saveProfile(String displayName, String username) async {
    final oldDisplayName = _displayName;
    final oldUsername = _username;

    final newUsername = username.trim().toLowerCase();

    // Update the screen immediately.
    setState(() {
      _displayName = displayName;
      _username = newUsername;
    });

    try {
      await _userService.updateUsername(newUsername);

      await _userService.saveProfile(displayName: displayName);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully.')),
      );
    } on UsernameAlreadyInUseException {
      if (!mounted) return;

      setState(() {
        _displayName = oldDisplayName;
        _username = oldUsername;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This username is already taken.')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _displayName = oldDisplayName;
        _username = oldUsername;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save profile. Please try again.'),
        ),
      );
    }
  }

  Future<void> _showEditProfileDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) =>
          _EditProfileDialog(displayName: _displayName, username: _username),
    );

    if (!mounted || result == null) return;

    await _saveProfile(result['displayName']!, result['username']!);
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
        child: Center(child: CircularProgressIndicator(color: _navy)),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextButton.icon(
          onPressed: provider.hasMoreTasks ? provider.loadMoreTasks : null,
          icon: const Icon(Icons.expand_more),
          label: const Text('Load More Tasks'),
          style: TextButton.styleFrom(foregroundColor: _navy),
        ),
      ),
    );
  }

  Widget _buildFilterBar(TaskProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF2)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 5,
        runSpacing: 5,
        children: ['All', 'Pending', 'Completed'].map((filter) {
          final isSelected = provider.selectedFilter == filter;

          final selectedColor = switch (filter) {
            'Pending' => const Color(0xFFFFE5B5),
            'Completed' => _green,
            _ => _navy,
          };

          final selectedTextColor = switch (filter) {
            'Pending' => const Color(0xFF855000),
            'Completed' => const Color(0xFF176B3A),
            _ => Colors.white,
          };

          return ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => provider.changeFilter(filter),
            backgroundColor: Colors.white,
            selectedColor: selectedColor,
            side: BorderSide(
              color: isSelected ? selectedColor : Colors.transparent,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
            labelStyle: TextStyle(
              color: isSelected ? selectedTextColor : const Color(0xFF647084),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 75, 24, 24),
      children: [
        Icon(
          Icons.task_alt_rounded,
          size: 68,
          color: _navy.withValues(alpha: 0.25),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF647084),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 72,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _username.isNotEmpty
                  ? 'Hello, ${_username[0].toUpperCase()}${_username.substring(1)}'
                  : _displayName.isNotEmpty
                  ? 'Hello, $_displayName'
                  : 'My Tasks',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Stay focused. Get things done.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFD6DFED),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _pickProfileImage,
            tooltip: 'Choose profile image',
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.75),
                  width: 1.5,
                ),
                color: Colors.white.withValues(alpha: 0.15),
              ),
              child: CircleAvatar(
                backgroundColor: Colors.transparent,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                    ? NetworkImage(_profileImageUrl!)
                    : null,
                child:
                    _profileImage == null &&
                        (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                    ? const Icon(Icons.person, color: Colors.white, size: 22)
                    : null,
              ),
            ),
          ),
          IconButton(
            onPressed: _showEditProfileDialog,
            tooltip: 'Edit profile',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.13),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.edit_outlined, size: 21),
          ),
          IconButton(
            onPressed: _logout,
            tooltip: 'Log out',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.13),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.logout_rounded, size: 21),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Consumer<TaskProvider>(
            builder: (context, provider, child) {
              return _buildFilterBar(provider);
            },
          ),
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: _navy),
                  );
                }

                if (provider.hasStreamError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          size: 48,
                          color: Color(0xFF9AA4B2),
                        ),
                        const SizedBox(height: 12),
                        const Text('Something went wrong loading tasks.'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: provider.retryTasksStream,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _navy,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final tasks = provider.tasks;

                if (tasks.isEmpty) {
                  final message = switch (provider.selectedFilter) {
                    'Pending' => 'No pending tasks.',
                    'Completed' => 'No completed tasks.',
                    _ => 'No tasks yet. Tap + to add one!',
                  };

                  return Column(
                    children: [
                      Expanded(child: _buildEmptyState(message)),
                      if (provider.hasMoreTasks) _buildLoadMoreButton(provider),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                  itemCount: tasks.length + (provider.hasMoreTasks ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == tasks.length) {
                      return _buildLoadMoreButton(provider);
                    }

                    final task = tasks[index];

                    return TaskTile(
                      key: ValueKey(task.id),
                      taskId: task.id,
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
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        child: const Icon(Icons.add, size: 29),
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final String displayName;
  final String username;

  const _EditProfileDialog({required this.displayName, required this.username});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _usernameController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _displayNameController = TextEditingController(text: widget.displayName);

    _usernameController = TextEditingController(text: widget.username);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit profile'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _displayNameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixText: '@',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final username = value?.trim() ?? '';

                if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username)) {
                  return 'Use 3–20 letters, numbers, or underscores.';
                }

                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;

                  Navigator.of(context).pop({
                    'displayName': _displayNameController.text.trim(),
                    'username': _usernameController.text.trim(),
                  });
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
