import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotesPage extends StatefulWidget {
  final String roomId;
  NotesPage({required this.roomId});

  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _noteController = TextEditingController();
  List<Map<String, dynamic>> _notes = [];

  @override
  void initState() {
    super.initState();
    _fetchNotes();
    _subscribeToNotes();
  }

  Future<void> _fetchNotes() async {
    final data = await supabase.from('notes').select().eq('room_id', widget.roomId);
    setState(() {
      _notes = data;
    });
  }

  void _subscribeToNotes() {
    supabase.channel('notes_channel').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notes',
      callback: (_) => _fetchNotes(),
    ).subscribe();
  }

  Future<void> _addNote() async {
    if (_noteController.text.isEmpty) return;
    await supabase.from('notes').insert({
      'room_id': widget.roomId,
      'content': _noteController.text,
    });
    _noteController.clear();
  }

  @override
  void dispose() {
    supabase.channel('notes_channel').unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notas")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(_notes[index]['content']));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(controller: _noteController, decoration: InputDecoration(hintText: "Escribe una nota...")),
                ),
                IconButton(icon: Icon(Icons.send), onPressed: _addNote),
              ],
            ),
          ),
        ],
      ),
    );
  }
}