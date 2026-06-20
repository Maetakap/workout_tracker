import 'package:flutter/material.dart';

class SwipeableListItem extends StatelessWidget {
  final Widget child;
  final Future<bool?> Function() onDeleteConfirm;
  final VoidCallback? onEdit;
  final Future<void> Function() onDeleted;

  const SwipeableListItem({
    required super.key,
    required this.child,
    required this.onDeleteConfirm,
    required this.onDeleted,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key!,
      // 右→左スワイプで削除
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      // 左→右スワイプで編集
      background: Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await onDeleteConfirm();
        } else {
          onEdit?.call();
          return false;
        }
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await onDeleted();
        }
      },
      child: child,
    );
  }
}
