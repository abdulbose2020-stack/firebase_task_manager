import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.taskId,
    required this.priorityLabel,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final String taskId;
  final String priorityLabel;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color get _priorityBackground {
    switch (priorityLabel) {
      case 'High':
        return const Color(0xFFFFE4E4);
      case 'Medium':
        return const Color(0xFFFFF0D5);
      default:
        return const Color(0xFFE3EDFF);
    }
  }

  Color get _priorityForeground {
    switch (priorityLabel) {
      case 'High':
        return const Color(0xFFCC3434);
      case 'Medium':
        return const Color(0xFF986000);
      default:
        return const Color(0xFF2856A3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<TaskProvider, Task?>(
      selector: (context, provider) {
        return provider.getTaskById(taskId);
      },
      builder: (context, task, child) {
        if (task == null) {
          return const SizedBox.shrink();
        }

        final isCompleted = task.completed;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFFD8EDE0)
                  : const Color(0xFFE9EDF3),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF172B4D).withValues(alpha: 0.045),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            leading: Checkbox(
              value: isCompleted,
              onChanged: (value) {
                if (value != null) {
                  onToggle(value);
                }
              },
              activeColor: const Color(0xFF24945A),
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            title: Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isCompleted
                    ? const Color(0xFF929BA8)
                    : const Color(0xFF263449),
                decoration: isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                decorationColor: const Color(0xFF929BA8),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFFE1F4E9)
                          : _priorityBackground,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      isCompleted ? 'Completed' : priorityLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCompleted
                            ? const Color(0xFF176B3A)
                            : _priorityForeground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onEdit,
                  tooltip: 'Edit task',
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xFF526B91),
                    backgroundColor: const Color(0xFFEEF2F8),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 19),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Delete task',
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    foregroundColor: const Color(0xFFD64545),
                    backgroundColor: const Color(0xFFFFEEEE),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 19),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}