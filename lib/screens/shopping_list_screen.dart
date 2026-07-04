import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_list_provider.dart';
import '../theme.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final TextEditingController _addController = TextEditingController();

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  void _addItem(ShoppingListProvider provider) {
    final text = _addController.text.trim();
    if (text.isNotEmpty) {
      provider.addItem(text);
      _addController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShoppingListProvider>(
      builder: (context, provider, _) {
        final unchecked = provider.unchecked;
        final checked = provider.checked;

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            backgroundColor: AppTheme.bgDark,
            title: const Text('Shopping List'),
            centerTitle: true,
            actions: [
              if (provider.items.isNotEmpty)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppTheme.textPrimary),
                  color: AppTheme.bgCard,
                  onSelected: (value) {
                    if (value == 'clear_checked') {
                      provider.clearChecked();
                    } else if (value == 'clear_all') {
                      _confirmClearAll(context, provider);
                    }
                  },
                  itemBuilder: (_) => [
                    if (checked.isNotEmpty)
                      const PopupMenuItem(
                        value: 'clear_checked',
                        child: Text('Remove checked',
                            style:
                                TextStyle(color: AppTheme.textPrimary)),
                      ),
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: Text('Clear all',
                          style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              // Add item input
              Container(
                color: AppTheme.bgCard,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppTheme.bgElevated,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _addController,
                          style: const TextStyle(
                              color: AppTheme.textPrimary, fontSize: 15),
                          decoration: const InputDecoration(
                            hintText: 'Add an item...',
                            hintStyle: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 15),
                            prefixIcon: Icon(Icons.add_rounded,
                                color: AppTheme.textSecondary, size: 20),
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 13),
                          ),
                          onSubmitted: (_) => _addItem(provider),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _addItem(provider),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.divider),
              // Progress bar
              if (provider.items.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: checked.length / provider.items.length,
                            backgroundColor: AppTheme.bgElevated,
                            valueColor: const AlwaysStoppedAnimation(
                                AppTheme.success),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${checked.length}/${provider.items.length}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // List
              Expanded(
                child: provider.items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shopping_basket_outlined,
                                color: AppTheme.textSecondary, size: 64),
                            const SizedBox(height: 16),
                            const Text(
                              'Your shopping list is empty.\nAdd ingredients from any recipe.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding:
                            const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        children: [
                          if (unchecked.isNotEmpty) ...[
                            _SectionLabel(
                                label: 'To get',
                                count: unchecked.length),
                            const SizedBox(height: 6),
                            ...unchecked.map((item) => _ShoppingItemTile(
                                  item: item,
                                  onToggle: () =>
                                      provider.toggleItem(item.id),
                                  onRemove: () =>
                                      provider.removeItem(item.id),
                                )),
                          ],
                          if (checked.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _SectionLabel(
                                label: 'Got it',
                                count: checked.length),
                            const SizedBox(height: 6),
                            ...checked.map((item) => _ShoppingItemTile(
                                  item: item,
                                  onToggle: () =>
                                      provider.toggleItem(item.id),
                                  onRemove: () =>
                                      provider.removeItem(item.id),
                                )),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmClearAll(
      BuildContext context, ShoppingListProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Clear all items?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
            'This will remove everything from your shopping list.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              provider.clearAll();
              Navigator.pop(context);
            },
            child: const Text('Clear all',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final int count;

  const _SectionLabel({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.bgElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShoppingItemTile extends StatelessWidget {
  final item;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  const _ShoppingItemTile({
    required this.item,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: item.isChecked ? AppTheme.success : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: item.isChecked
                      ? AppTheme.success
                      : AppTheme.textSecondary,
                  width: 2,
                ),
              ),
              child: item.isChecked
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      color: item.isChecked
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      decoration: item.isChecked
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: AppTheme.textSecondary,
                    ),
                  ),
                  if (item.recipeTitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.recipeTitle!,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            // Delete
            GestureDetector(
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.close_rounded,
                    color: AppTheme.textSecondary, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}