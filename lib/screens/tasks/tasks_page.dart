import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'edit_task_page.dart';

class NotesPage extends StatefulWidget {
  final String roomId;
  final String roomName;

  const NotesPage({Key? key, required this.roomId, required this.roomName}) : super(key: key);

  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = false;
  DateTime? _reminderDate;
  DateTime? _dueDate;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  @override
  void initState() {
    super.initState();
    _fetchNotes();
    _subscribeToNotes();
  }

  Future<void> _fetchNotes() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('notes')
          .select()
          .eq('room_id', widget.roomId)
          .order('created_at', ascending: false);
      setState(() {
        _notes = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar tareas: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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

  void _subscribeToNotes() {
    supabase.channel('notes_channel').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'notes',
      callback: (_) => _fetchNotes(),
    ).subscribe();
  }

  Future<void> _addNote() async {
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

    try {
      await supabase.from('notes').insert({
        'room_id': widget.roomId,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'reminder': _reminderDate?.toIso8601String(),
        'due_date': _dueDate?.toIso8601String(),
        'is_done': false,
      });

      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _reminderDate = null;
        _dueDate = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear tarea: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _toggleNoteStatus(String noteId, bool currentStatus) async {
    try {
      await supabase
          .from('notes')
          .update({'is_done': !currentStatus})
          .eq('id', noteId);
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
    }
  }

  Future<void> _confirmAndDeleteNote(String noteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Eliminar tarea',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('¿Estás seguro de que quieres eliminar esta tarea?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await supabase.from('notes').delete().eq('id', noteId);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar tarea: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Widget _buildDateChip(DateTime? date, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        avatar: Icon(Icons.calendar_today, size: 18),
        label: Text(
          date != null ? _dateFormat.format(date) : label,
          style: TextStyle(
            fontSize: 12,
          ),
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

  Widget _buildNoteItem(Map<String, dynamic> note, bool isCompleted) {
    final reminder = note['reminder'] != null ? DateTime.parse(note['reminder']) : null;
    final dueDate = note['due_date'] != null ? DateTime.parse(note['due_date']) : null;
    final isOverdue = dueDate != null && !isCompleted && dueDate.isBefore(DateTime.now());

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      color: isOverdue
          ? Colors.red[50]
          : Theme.of(context).colorScheme.surfaceVariant,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditNotePage(
                note: note,
                onNoteUpdated: _fetchNotes,
              ),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note['title'] ?? 'Sin título',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted
                            ? Colors.grey
                            : (isOverdue ? Colors.red : null),
                      ),
                    ),
                  ),
                  Checkbox(
                    value: note['is_done'] ?? false,
                    onChanged: (value) => _toggleNoteStatus(note['id'], note['is_done']),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              if (note['description'] != null && note['description'].isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    note['description'],
                    style: TextStyle(
                      color: isCompleted ? Colors.grey[600] : null,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              if (reminder != null || dueDate != null)
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (reminder != null)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications, size: 16, color: Colors.blue),
                              SizedBox(width: 4),
                              Text(
                                _dateFormat.format(reminder),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (dueDate != null)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOverdue ? Colors.red[50] : Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event,
                                size: 16,
                                color: isOverdue ? Colors.red : Colors.green,
                              ),
                              SizedBox(width: 4),
                              Text(
                                _dateFormat.format(dueDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOverdue ? Colors.red : Colors.green,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.delete_outline, size: 20),
                  color: Colors.red[400],
                  onPressed: () => _confirmAndDeleteNote(note['id']),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    supabase.channel('notes_channel').unsubscribe();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final incompleteNotes = _notes.where((note) => !(note['is_done'] ?? false)).toList();
    final completedNotes = _notes.where((note) => note['is_done'] ?? false).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.roomName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            indicator: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                            tabs: [
                              Tab(text: 'Pendientes (${incompleteNotes.length})'),
                              Tab(text: 'Completadas (${completedNotes.length})'),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        Expanded(
                          child: TabBarView(
                            children: [
                              incompleteNotes.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'No hay tareas pendientes',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      itemCount: incompleteNotes.length,
                                      itemBuilder: (context, index) =>
                                          _buildNoteItem(incompleteNotes[index], false),
                                    ),
                              completedNotes.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.assignment_turned_in_outlined,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'No hay tareas completadas',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      itemCount: completedNotes.length,
                                      itemBuilder: (context, index) =>
                                          _buildNoteItem(completedNotes[index], true),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateChip(
                        _reminderDate,
                        'Agregar recordatorio',
                        () => _selectDate(context, true),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildDateChip(
                        _dueDate,
                        'Agregar fecha límite',
                        () => _selectDate(context, false),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
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
                    onPressed: _addNote,
                    child: Text(
                      'Agregar tarea',
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
        ],
      ),
    );
  }
}