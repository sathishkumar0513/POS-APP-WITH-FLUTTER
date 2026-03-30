import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/services/user_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UserService _service = UserService();
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await _service.getAllUsers();
    if (mounted) setState(() { _users = users; _isLoading = false; });
  }

  Future<void> _delete(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete "${user.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.deleteUser(user.id!);
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await showDialog(context: context, builder: (_) => _UserFormDialog(onSaved: _loadUsers));
        },
        label: const Text('Add User'),
        icon: const Icon(Icons.person_add),
        backgroundColor: const Color(0xFF1A237E),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('No users found'))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (_, i) {
                    final u = _users[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: u.role == 'admin' ? Colors.red.shade100 : Colors.blue.shade100,
                          child: Icon(u.role == 'admin' ? Icons.admin_panel_settings : Icons.person, color: u.role == 'admin' ? Colors.red : Colors.blue),
                        ),
                        title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('@${u.username} | ${u.role.toUpperCase()}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: u.isActive,
                              onChanged: (v) async {
                                await _service.updateUser(u.copyWith(isActive: v));
                                _loadUsers();
                              },
                            ),
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () async {
                              await showDialog(context: context, builder: (_) => _UserFormDialog(user: u, onSaved: _loadUsers));
                            }),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(u)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _UserFormDialog extends StatefulWidget {
  final UserModel? user;
  final VoidCallback onSaved;
  const _UserFormDialog({this.user, required this.onSaved});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final UserService _service = UserService();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'cashier';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _nameController.text = widget.user!.name;
      _usernameController.text = widget.user!.username;
      _role = widget.user!.role;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    try {
      final exists = await _service.usernameExists(_usernameController.text.trim(), excludeId: widget.user?.id);
      if (exists) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username already exists'), backgroundColor: Colors.red));
        return;
      }
      final user = UserModel(
        id: widget.user?.id,
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.isNotEmpty ? _passwordController.text : (widget.user?.password ?? ''),
        role: _role,
        isActive: widget.user?.isActive ?? true,
      );
      if (widget.user == null) {
        await _service.insertUser(user);
      } else {
        await _service.updateUser(user);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null ? 'Add User' : 'Edit User'),
      content: SizedBox(
        width: 320,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Username is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: widget.user == null ? 'Password *' : 'New Password (leave blank to keep)',
                  border: const OutlineInputBorder(),
                ),
                validator: widget.user == null ? (v) => v == null || v.isEmpty ? 'Password is required' : null : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                ],
                onChanged: (v) { if (v != null) setState(() { _role = v; }); },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
