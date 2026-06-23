import 'package:flutter/material.dart';

/// 保存ボタン固定バー（入力・編集画面で共通利用）
class SaveBar extends StatelessWidget {
  const SaveBar({
    super.key,
    required this.canSave,
    required this.isSaving,
    required this.onSave,
  });

  final bool canSave;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: FilledButton(
        onPressed: canSave ? onSave : null,
        child: isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('保存'),
      ),
    );
  }
}

/// スター入力（セッション単位の没頭度）
class StarInput extends StatelessWidget {
  const StarInput({super.key, required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final selected = value != null && i < value!;
        return IconButton(
          icon: Icon(
            selected ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: () => onChanged(i + 1),
        );
      }),
    );
  }
}

/// セクションラベル
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: Colors.grey),
      ),
    );
  }
}
