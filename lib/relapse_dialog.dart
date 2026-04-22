import 'package:flutter/material.dart';
import 'app_theme.dart';

class RelapseDialog extends StatefulWidget {
  final String habitName;
  final String habitIcon;
  final Function(String) onConfirm;

  const RelapseDialog({
    super.key,
    required this.habitName,
    required this.habitIcon,
    required this.onConfirm,
  });

  @override
  State<RelapseDialog> createState() => _RelapseDialogState();
}

class _RelapseDialogState extends State<RelapseDialog> {
  final TextEditingController _customReasonController = TextEditingController();
  String? _selectedReason;
  bool _isCustomReason = false;
  
  final List<String> _commonReasons = [
    '😫 Сильный стресс',
    '😴 Усталость',
    '🎉 Праздник/мероприятие',
    '👥 Давление окружения',
    '😔 Плохое настроение',
    '🎮 Отвлечение/прокрастинация',
    '🍷 Алкоголь',
    '😤 Ссора с кем-то',
    '🕐 Неконтролируемый импульс',
    '📱 Социальные сети',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Иконка и название
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(widget.habitIcon, style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Срыв привычки "${widget.habitName}"',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '✨ Бывает...',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),
              
              // Выбор причины
              const Text(
                'Выберите причину срыва:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonReasons.map((reason) {
                  final isSelected = _selectedReason == reason && !_isCustomReason;
                  return FilterChip(
                    label: Text(reason, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedReason = selected ? reason : null;
                        _isCustomReason = false;
                        if (!selected) {
                          _customReasonController.clear();
                        }
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.red,
                    checkmarkColor: Colors.white,
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              
              // Своя причина
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isCustomReason = true;
                    _selectedReason = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isCustomReason ? Colors.red.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _isCustomReason ? Colors.red : Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_note,
                        color: _isCustomReason ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Своя причина',
                        style: TextStyle(
                          color: _isCustomReason ? Colors.red : Colors.grey,
                          fontWeight: _isCustomReason ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              if (_isCustomReason) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _customReasonController,
                  maxLines: 3,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Напишите причину срыва...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: const Icon(Icons.edit, color: Colors.red),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Кнопки
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _getReasonText().isNotEmpty
                          ? () {
                              widget.onConfirm(_getReasonText());
                              Navigator.pop(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Подтвердить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getReasonText() {
    if (_isCustomReason) {
      return _customReasonController.text.trim();
    }
    return _selectedReason ?? '';
  }
}