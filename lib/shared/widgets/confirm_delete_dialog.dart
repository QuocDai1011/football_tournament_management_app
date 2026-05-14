import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ConfirmDeleteDialog extends StatefulWidget {
  final String itemName;
  final String itemType; // 'tournament', 'team', 'match', etc.
  final VoidCallback onConfirm;

  const ConfirmDeleteDialog({
    super.key,
    required this.itemName,
    required this.itemType,
    required this.onConfirm,
  });

  @override
  State<ConfirmDeleteDialog> createState() => _ConfirmDeleteDialogState();
}

class _ConfirmDeleteDialogState extends State<ConfirmDeleteDialog> {
  bool _showNameConfirmation = false;
  final _controller = TextEditingController();
  bool _isNameMatched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showNameConfirmation) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete ${widget.itemType}?'),
        content: Text('Are you sure you want to delete "${widget.itemName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showNameConfirmation = true;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Delete'),
          ),
        ],
      );
    }

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Confirm Deletion'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Please type "${widget.itemName}" to confirm.'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (value) {
              setState(() {
                _isNameMatched = value.trim() == widget.itemName.trim();
              });
            },
            decoration: InputDecoration(
              hintText: 'Enter name here',
              errorText: _controller.text.isNotEmpty && !_isNameMatched ? 'Name doesn\'t match' : null,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _isNameMatched
              ? () {
                  Navigator.pop(context);
                  widget.onConfirm();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            disabledBackgroundColor: AppColors.error.withOpacity(0.3),
          ),
          child: const Text('Delete Permanently'),
        ),
      ],
    );
  }
}
