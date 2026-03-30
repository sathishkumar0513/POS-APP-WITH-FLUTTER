import 'package:flutter/material.dart';
import '../../core/models/customer_model.dart';
import '../../core/services/customer_service.dart';
import 'customer_form_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final CustomerService _service = CustomerService();
  List<CustomerModel> _customers = [];
  List<CustomerModel> _filtered = [];
  final _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    final customers = await _service.getAllCustomers();
    if (mounted) setState(() { _customers = customers; _filtered = customers; _isLoading = false; });
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty ? _customers : _customers.where((c) =>
        c.name.toLowerCase().contains(q) ||
        (c.phone?.toLowerCase().contains(q) ?? false) ||
        (c.email?.toLowerCase().contains(q) ?? false)
      ).toList();
    });
  }

  Future<void> _delete(CustomerModel customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Delete "${customer.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.deleteCustomer(customer.id!);
      _loadCustomers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerFormScreen()));
          _loadCustomers();
        },
        label: const Text('Add Customer'),
        icon: const Icon(Icons.person_add),
        backgroundColor: const Color(0xFF1A237E),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('No customers found'))
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final c = _filtered[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal.shade100,
                                child: Text(c.name[0].toUpperCase(), style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (c.phone != null) Text(c.phone!, style: const TextStyle(fontSize: 12)),
                                  if (c.email != null) Text(c.email!, style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              isThreeLine: c.phone != null && c.email != null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () async {
                                    await Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerFormScreen(customer: c)));
                                    _loadCustomers();
                                  }),
                                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(c)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
