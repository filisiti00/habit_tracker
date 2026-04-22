import 'package:flutter/material.dart';
import 'calendar_note_model.dart';
import 'app_theme.dart';

class AddNoteDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Function(CalendarNote) onAddNote;

  const AddNoteDialog({
    super.key,
    required this.selectedDate,
    required this.onAddNote,
  });

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  Mood _selectedMood = Mood.neutral;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '📝 Добавить заметку',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.selectedDate.day}.${widget.selectedDate.month}.${widget.selectedDate.year}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'Название (например: Важная встреча)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Описание (необязательно)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'Какое у вас настроение?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                
                // Сетка настроений
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 1,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: Mood.values.length,
                  itemBuilder: (context, index) {
                    final mood = Mood.values[index];
                    final isSelected = _selectedMood == mood;
                    
                    return GestureDetector(
                      onTap: () => setState(() => _selectedMood = mood),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: mood.color.withOpacity(isSelected ? 0.3 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? mood.color : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: mood.color.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ] : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              mood.emoji,
                              style: TextStyle(fontSize: isSelected ? 32 : 28),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mood.label,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? mood.color : Colors.grey,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Отмена'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _titleController.text.isNotEmpty
                            ? () {
                                final note = CalendarNote(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  title: _titleController.text,
                                  description: _descriptionController.text,
                                  date: widget.selectedDate,
                                  mood: _selectedMood,
                                  createdAt: DateTime.now(),
                                );
                                widget.onAddNote(note);
                                Navigator.pop(context);
                              }
                            : null,
                        style: ButtonStyles.primaryButton,
                        child: const Text('Добавить'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}