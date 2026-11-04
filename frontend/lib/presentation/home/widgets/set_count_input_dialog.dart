import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../ui/app_colors.dart';

class SetCountResult {
  const SetCountResult({
    required this.sets,
    required this.applyToAll,
  });

  final int sets;
  final bool applyToAll;
}

/// 목표 세트 수 입력 및 일괄 적용 다이얼로그
class SetCountInputDialog extends StatefulWidget {
  const SetCountInputDialog({
    super.key,
    required this.initialSets,
    this.exerciseName,
    this.showApplyToAll = true,
  });

  final int initialSets;
  final String? exerciseName;
  final bool showApplyToAll;

  static Future<SetCountResult?> show(
    BuildContext context, {
    required int initialSets,
    String? exerciseName,
    bool showApplyToAll = true,
  }) {
    return showDialog<SetCountResult>(
      context: context,
      builder: (ctx) => SetCountInputDialog(
        initialSets: initialSets,
        exerciseName: exerciseName,
        showApplyToAll: showApplyToAll,
      ),
    );
  }

  @override
  State<SetCountInputDialog> createState() => _SetCountInputDialogState();
}

class _SetCountInputDialogState extends State<SetCountInputDialog> {
  late int _selectedSets;
  late bool _applyToAll;
  late final TextEditingController _textController;

  final List<int> _quickPresets = const [2, 3, 4, 5];

  @override
  void initState() {
    super.initState();
    _selectedSets = widget.initialSets.clamp(1, 10);
    _applyToAll = widget.exerciseName == null ? true : false;
    _textController = TextEditingController(text: '$_selectedSets');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _updateSets(int newSets) {
    final clamped = newSets.clamp(1, 10);
    setState(() {
      _selectedSets = clamped;
      _textController.text = '$clamped';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGlobal = widget.exerciseName == null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fitness_center_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGlobal ? '목표 세트 일괄 설정' : '목표 세트 변경',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      if (!isGlobal)
                        Text(
                          widget.exerciseName!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stepper & Direct Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: _selectedSets > 1
                        ? () => _updateSets(_selectedSets - 1)
                        : null,
                    icon: const Icon(Icons.remove, size: 20),
                    tooltip: '1세트 감소',
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _textController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null && parsed >= 1 && parsed <= 10) {
                          setState(() {
                            _selectedSets = parsed;
                          });
                        }
                      },
                    ),
                  ),
                  const Text(
                    '세트',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton.filledTonal(
                    onPressed: _selectedSets < 10
                        ? () => _updateSets(_selectedSets + 1)
                        : null,
                    icon: const Icon(Icons.add, size: 20),
                    tooltip: '1세트 추가',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Quick Preset Chips
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: _quickPresets.map((preset) {
                final isSelected = _selectedSets == preset;
                return ChoiceChip(
                  label: Text('$preset세트'),
                  selected: isSelected,
                  selectedColor: AppColors.primaryContainer,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                  onSelected: (selected) {
                    if (selected) _updateSets(preset);
                  },
                );
              }).toList(),
            ),

            if (widget.showApplyToAll && !isGlobal) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  setState(() {
                    _applyToAll = !_applyToAll;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _applyToAll,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            _applyToAll = val ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          '오늘 모든 근력 운동에 일괄 적용',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        SetCountResult(
                          sets: _selectedSets,
                          applyToAll: isGlobal ? true : _applyToAll,
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '적용하기',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
