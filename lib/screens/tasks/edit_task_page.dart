import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class EditNotePage extends StatefulWidget {
  final Map<String, dynamic> note;
  final Function() onNoteUpdated;

  const EditNotePage({
    Key? key,
    required this.note,
    required this.onNoteUpdated,
  }) : super(key: key);

  @override
  _EditNotePageState createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  DateTime? _reminderDate;
  DateTime? _dueDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.note['title'] ?? '';
    _descriptionController.text = widget.note['description'] ?? '';
    if (widget.note['reminder'] != null) {
      _reminderDate = DateTime.parse(widget.note['reminder']);
    }
    if (widget.note['due_date'] != null) {
      _dueDate = DateTime.parse(widget.note['due_date']);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isReminder) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).colorScheme.primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final DateTime fullDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isReminder) {
            _reminderDate = fullDate;
          } else {
            _dueDate = fullDate;
          }
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El título es requerido'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await supabase.from('notes').update({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'reminder': _reminderDate?.toIso8601String(),
        'due_date': _dueDate?.toIso8601String(),
      }).eq('id', widget.note['id']);

      widget.onNoteUpdated();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar tarea: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Widget _buildDateChip(DateTime? date, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        avatar: Icon(Icons.calendar_today, size: 18),
        label: Text(
          date != null ? _dateFormat.format(date) : label,
          style: TextStyle(fontSize: 12),
        ),
        deleteIcon: Icon(Icons.close, size: 18),
        onDeleted: date != null
            ? () => setState(() {
                if (label.contains('Recordatorio')) {
                  _reminderDate = null;
                } else {
                  _dueDate = null;
                }
              })
            : null,
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = widget.note['is_done'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Editar Tarea',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.pending_actions,
                    color: isCompleted ? Colors.green : Colors.orange,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Estado: ${isCompleted ? 'Completada' : 'Pendiente'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isCompleted ? Colors.green[800] : Colors.orange[800],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Título',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Ingrese el título',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: 20),
            Text(
              'Descripción',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'Ingrese la descripción (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 24),
            Text(
              'Fechas importantes',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDateChip(
                    _reminderDate,
                    'Recordatorio',
                    () => _selectDate(context, true),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildDateChip(
                    _dueDate,
                    'Fecha límite',
                    () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: _isSaving ? null : _saveChanges,
                child: _isSaving
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Guardar cambios',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}