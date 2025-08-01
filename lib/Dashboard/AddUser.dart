
import 'dart:convert';
import 'package:flutter/material.dart';
import '../Database/UserRepository.dart';
import '../Model/UserModel.dart';

class AddUsers extends StatefulWidget {
  final UserModel? user;
  const AddUsers({super.key, this.user});

  @override
  State<AddUsers> createState() => _AddUsersState();
}

class _AddUsersState extends State<AddUsers> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final numberController = TextEditingController();
  final addressController = TextEditingController();
  String selectedRole = 'User';

  String selectedStatus = 'Active';
  bool selectAll = false;

  final List<String> modules = [
    'Dashboard',
    'Customer',
    'Product',
    'Transport',
    'Quotation',
    'Invoice',
    'Purchase',
    'Account',
    'Category',
    'Transactions',
    'Reports',
  ];

  Map<String, Map<String, bool>> permissions = {};

  @override
  void initState() {
    super.initState();
    for (var module in modules) {
      permissions[module] = {
        'View': false,
        'Create': false,
        'Edit': false,
      };
    }
  }

  void toggleSelectAll(bool? value) {
    setState(() {
      selectAll = value ?? false;
      for (var module in permissions.keys) {
        for (var action in permissions[module]!.keys) {
          permissions[module]![action] = selectAll;
        }
      }
    });
  }

  void togglePermission(String module, String action, bool? value) {
    setState(() {
      permissions[module]![action] = value ?? false;

      // If any permission is false, uncheck Select All
      selectAll = permissions.values.every((actionMap) =>
          actionMap.values.every((val) => val == true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(title: Text("Add User")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildInputField("Email", emailController, Icons.email),
                  const SizedBox(height: 12),
                  buildInputField("Password", passwordController, Icons.lock, obscure: true),
                  const SizedBox(height: 12),
                  buildInputField("Number", numberController, Icons.phone),
                  const SizedBox(height: 12),
                  buildInputField("Address", addressController, Icons.home),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Role",
                      border: OutlineInputBorder(),
                    ),
                    value: selectedRole,
                    items: ['User', 'Admin'].map((role) {
                      return DropdownMenuItem(value: role, child: Text(role));
                    }).toList(),
                    onChanged: (val) => setState(() => selectedRole = val!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Status",
                      border: OutlineInputBorder(),
                    ),
                    value: selectedStatus,
                    items: ['Active', 'Inactive']
                        .map((status) => DropdownMenuItem(
                      child: Text(status),
                      value: status,
                    ))
                        .toList(),
                    onChanged: (value) => setState(() => selectedStatus = value!),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Checkbox(value: selectAll, onChanged: toggleSelectAll),
                      const Text("All"),
                    ],
                  ),
                  buildPermissionTable(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final user = UserModel(
                          id: widget.user?.id, // Use existing ID if editing
                          shopName: 'Demo Shop',
                          address: addressController.text,
                          email: emailController.text,
                          number: numberController.text,
                          password: passwordController.text,
                          role: selectedRole,
                          status: selectedStatus,
                          permissions: jsonEncode(permissions),
                        );

                        final repo = UserRepository();
                        await repo.init();

                        if (widget.user == null) {
                          await repo.registerUser(user);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("User Created ✅")),
                          );
                        } else {
                          await repo.updateUser(user); // You'll define this
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("User Updated ✏️")),
                          );
                        }

                        Navigator.pop(context); // Return to previous screen
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                      child: Text("Submit", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInputField(String label, TextEditingController controller, IconData icon,
      {bool obscure = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(),
      ),
      validator: (val) => val == null || val.isEmpty ? "Enter $label" : null,
    );
  }

  Widget buildPermissionTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FixedColumnWidth(150),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
        3: FlexColumnWidth(),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.blueGrey.shade50),
          children: const [
              Padding(padding: EdgeInsets.all(8), child: Text('Module')),
              Padding(padding: EdgeInsets.all(8), child: Text('View')),
              Padding(padding: EdgeInsets.all(8), child: Text('Create')),
              Padding(padding: EdgeInsets.all(8), child: Text('Edit')),
          ],
        ),
        ...modules.map((module) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(module),
              ),
              Checkbox(
                value: permissions[module]!['View'],
                onChanged: (val) => togglePermission(module, 'View', val),
              ),
              Checkbox(
                value: permissions[module]!['Create'],
                onChanged: (val) => togglePermission(module, 'Create', val),
              ),
              Checkbox(
                value: permissions[module]!['Edit'],
                onChanged: (val) => togglePermission(module, 'Edit', val),
              ),
            ],
          );
        }),
      ],
    );
  }
}
