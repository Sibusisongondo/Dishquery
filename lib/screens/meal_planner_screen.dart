import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meal_plan.dart';
import '../providers/meal_plan_provider.dart';
import '../theme.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  late DateTime _weekStart;
  late List<DateTime> _weekDays;

  @override
  void initState() {
    super.initState();
    _setWeek(DateTime.now());
  }

  void _setWeek(DateTime date) {
    final monday =
        date.subtract(Duration(days: date.weekday - 1));
    _weekStart = DateTime(monday.year, monday.month, monday.day);
    _weekDays = List.generate(
        7, (i) => _weekStart.add(Duration(days: i)));
  }

  void _prevWeek() => setState(() => _setWeek(_weekStart.subtract(const Duration(days: 7))));
  void _nextWeek() => setState(() => _setWeek(_weekStart.add(const Duration(days: 7))));

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String _monthLabel() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final start = _weekDays.first;
    final end = _weekDays.last;
    if (start.month == end.month) {
      return '${months[start.month - 1]} ${start.year}';
    }
    return '${months[start.month - 1]} – ${months[end.month - 1]} ${end.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MealPlanProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            backgroundColor: AppTheme.bgDark,
            title: const Text('Meal Plan'),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Week navigator
              Container(
                color: AppTheme.bgCard,
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded,
                          color: AppTheme.textPrimary),
                      onPressed: _prevWeek,
                    ),
                    Expanded(
                      child: Text(
                        _monthLabel(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded,
                          color: AppTheme.textPrimary),
                      onPressed: _nextWeek,
                    ),
                  ],
                ),
              ),
              // Day pills
              Container(
                color: AppTheme.bgCard,
                padding:
                    const EdgeInsets.only(bottom: 12, left: 12, right: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _weekDays.map((day) {
                    final isToday = _isToday(day);
                    const dayNames = [
                      'M', 'T', 'W', 'T', 'F', 'S', 'S'
                    ];
                    final hasEntries =
                        provider.entriesForDay(day).isNotEmpty;
                    return Column(
                      children: [
                        Text(
                          dayNames[day.weekday - 1],
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppTheme.primary
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: hasEntries && !isToday
                                  ? AppTheme.primary.withOpacity(0.4)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                color: isToday
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1, color: AppTheme.divider),
              // Day plan list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _weekDays.length,
                  itemBuilder: (context, i) {
                    final day = _weekDays[i];
                    final entries = provider.entriesForDay(day);
                    return _DayCard(
                      day: day,
                      isToday: _isToday(day),
                      entries: entries,
                      onRemove: (id) => provider.removeEntry(id),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayCard extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final List<MealPlanEntry> entries;
  final ValueChanged<String> onRemove;

  const _DayCard({
    required this.day,
    required this.isToday,
    required this.entries,
    required this.onRemove,
  });

  String _dayLabel() {
    if (isToday) return 'Today';
    const days = [
      'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return days[day.weekday - 1];
  }

  String _dateLabel() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[day.month - 1]} ${day.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? AppTheme.primary.withOpacity(0.4)
              : AppTheme.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Text(
                  _dayLabel(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isToday
                        ? AppTheme.primary
                        : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _dateLabel(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                'No meals planned — add recipes from the detail page.',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
            )
          else ...[
            const Divider(height: 1, color: AppTheme.divider),
            ...entries.map((entry) => _MealEntry(
                  entry: entry,
                  onRemove: () => onRemove(entry.id),
                )),
          ],
        ],
      ),
    );
  }
}

class _MealEntry extends StatelessWidget {
  final MealPlanEntry entry;
  final VoidCallback onRemove;

  const _MealEntry({required this.entry, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Meal type indicator
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.bgElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(entry.mealType.emoji,
                  style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          // Recipe info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.mealType.label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.recipe.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Thumb
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              entry.recipe.imageUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 52,
                height: 52,
                color: AppTheme.bgElevated,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Remove
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                color: AppTheme.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }
}