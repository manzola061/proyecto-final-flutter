import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../tasks/tasks_page.dart';
import '../auth/login_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _rooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRooms();
    _subscribeToRooms();
  }

  Future<void> _fetchRooms() async {
    try {
      final data = await supabase.from('rooms').select();
      setState(() {
        _rooms = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar listas'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _subscribeToRooms() {
    supabase.channel('rooms_channel').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'rooms',
      callback: (_) => _fetchRooms(),
    ).subscribe();
  }

  Future<void> _createRoom() async {
    final nameController = TextEditingController();
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debes estar autenticado para crear listas'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Nueva lista",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: "Nombre de la lista",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancelar",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () async {
              if (nameController.text.isEmpty) return;

              try {
                await supabase.from('rooms').insert({
                  'name': nameController.text,
                  'user_id': user.id,
                });
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al crear lista: $e'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            child: Text("Crear"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRoom(String roomId) async {
    try {
      await supabase.from('rooms').delete().eq('id', roomId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lista eliminada correctamente'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar lista: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Cerrar sesión",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text("¿Estás seguro de que quieres cerrar tu sesión?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "Cancelar",
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
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Cerrar sesión"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _signOut();
    }
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    supabase.channel('rooms_channel').unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Mis Listas",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person, size: 24),
            onPressed: () {
              final user = supabase.auth.currentUser;
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(user: user),
                  ),
                );
              }
            },
            tooltip: 'Perfil',
          ),
          IconButton(
            icon: Icon(Icons.logout, size: 24),
            onPressed: _confirmSignOut,
            tooltip: 'Cerrar sesión',
          ),
        ],
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : _rooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.list_rounded,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        "No hay listas aún",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Presiona el botón + para crear una",
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  itemCount: _rooms.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final room = _rooms[index];
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                      title: Text(
                        room['name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, size: 24),
                        color: Colors.red[400],
                        onPressed: () async {
                          bool confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Text(
                                "Eliminar lista",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              content: Text(
                                  "¿Estás seguro de que quieres eliminar esta lista?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: Text(
                                    "Cancelar",
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
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: Text("Eliminar"),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _deleteRoom(room['id']);
                          }
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotesPage(
                              roomId: room['id'],
                              roomName: room['name'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createRoom,
        child: Icon(Icons.add, size: 28),
        backgroundColor: theme.colorScheme.primary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}