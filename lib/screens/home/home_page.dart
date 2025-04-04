import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../notes/notes_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _rooms = [];

  @override
  void initState() {
    super.initState();
    _fetchRooms();
    _subscribeToRooms();
  }

  Future<void> _fetchRooms() async {
    final data = await supabase.from('rooms').select();
    setState(() {
      _rooms = data;
    });
  }

  void _subscribeToRooms() {
    supabase.channel('rooms_channel').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'rooms',
      callback: (_) => _fetchRooms(),
    ).subscribe();
  }

  Future<void> _createRoom() async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Crear nueva sala"),
        content: TextField(controller: nameController, decoration: InputDecoration(hintText: "Nombre de la sala")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              await supabase.from('rooms').insert({'name': nameController.text});
              Navigator.pop(context);
            },
            child: Text("Crear"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    supabase.channel('rooms_channel').unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Salas de Notas")),
      body: _rooms.isEmpty
          ? Center(child: Text("No hay salas aún."))
          : ListView.builder(
              itemCount: _rooms.length,
              itemBuilder: (context, index) {
                final room = _rooms[index];
                return ListTile(
                  title: Text(room['name']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NotesPage(roomId: room['id'])),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createRoom,
        child: Icon(Icons.add),
      ),
    );
  }
}