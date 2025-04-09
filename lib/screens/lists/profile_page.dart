import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  final User user;
  const ProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;
  late TextEditingController _nameController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.userMetadata?['name'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      await supabase.auth.updateUser(
        UserAttributes(data: {'name': _nameController.text}),
      );

      if (_passwordController.text.isNotEmpty) {
        await supabase.auth.updateUser(
          UserAttributes(password: _passwordController.text),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Perfil actualizado'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      
      setState(() {
        _isEditing = false;
        _passwordController.clear();
        _confirmPasswordController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAt = DateTime.parse(widget.user.createdAt).toLocal().toString().split('.')[0];

    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Perfil', style: TextStyle(color: theme.colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _isLoading ? null : _updateProfile,
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('GUARDAR', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 24, bottom: 32),
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              
              // Sección de información
              _buildInfoCard(
                context,
                title: 'Información de cuenta',
                children: [
                  _buildInfoRow('Correo', widget.user.email ?? 'No especificado'),
                  Divider(height: 24),
                  _isEditing
                      ? _buildEditableNameField()
                      : _buildInfoRow('Nombre', widget.user.userMetadata?['name'] ?? 'No especificado'),
                ],
              ),
              
              if (_isEditing) ...[
                SizedBox(height: 24),
                _buildInfoCard(
                  context,
                  title: 'Cambiar contraseña',
                  children: [
                    _buildPasswordField(
                      controller: _passwordController,
                      label: 'Nueva contraseña',
                      hint: 'Dejar vacío para no cambiar',
                      obscure: _obscurePassword,
                      onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    SizedBox(height: 16),
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      label: 'Confirmar contraseña',
                      obscure: _obscureConfirmPassword,
                      onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ],
                ),
              ],
              
              if (!_isEditing) ...[
                SizedBox(height: 24),
                _buildInfoCard(
                  context,
                  title: 'Detalles',
                  children: [
                    _buildInfoRow('ID', widget.user.id),
                    Divider(height: 24),
                    _buildInfoRow('Registrado', createdAt),
                  ],
                ),
              ],

              if (!_isEditing) 
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _isEditing = true),
                    child: Text('EDITAR PERFIL', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required String title, required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildEditableNameField() {
    return TextFormField(
      controller: _nameController,
      style: TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Nombre',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: UnderlineInputBorder(),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: UnderlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
      ),
    );
  }
}