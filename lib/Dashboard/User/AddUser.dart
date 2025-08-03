
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../Database/UserRepository.dart';
import '../../Model/UserModel.dart';

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
  final usernameController = TextEditingController();
  String selectedRole = 'user';

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

    final existingUser = widget.user;
    if (existingUser != null) {
      emailController.text = existingUser.email;
      passwordController.text = existingUser.password;
      numberController.text = existingUser.number;
      addressController.text = existingUser.address;
      usernameController.text = existingUser?.username ?? '';

      if (existingUser.role != null) {
        final role = existingUser.role!.trim().toLowerCase();
        if (role == 'admin' || role == 'user') {
          selectedRole = role;
        } else {
          selectedRole = 'user';
        }
      } else {
        selectedRole = 'user';
      }

      if (['Active', 'Inactive'].contains(existingUser.status)) {
        selectedStatus = existingUser.status!;
      } else {
        selectedStatus = 'Active';
      }

      try {
        final decodedPermissions = jsonDecode(existingUser.permissions ?? '{}');
        for (var module in decodedPermissions.keys) {
          if (permissions.containsKey(module)) {
            final modulePerms = decodedPermissions[module];
            for (var action in modulePerms.keys) {
              if (permissions[module]!.containsKey(action)) {
                permissions[module]![action] = modulePerms[action];
              }
            }
          }
        }

        selectAll = permissions.values.every(
              (perm) => perm.values.every((val) => val == true),
        );
      } catch (e) {
        debugPrint("Permission decode error: $e");
      }
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
      appBar: AppBar(
        title: Text(widget.user == null ? "Add User" : "Edit User"),
      ), body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildInputField(
                    "User Name",
                    usernameController,
                    Icons.person,
                    validator: (val) => validateRequired(val, "User Name"),
                  ),
                  const SizedBox(height: 12),
                  buildInputField(
                    "Email",
                    emailController,
                    Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 12),
                  buildInputField(
                    "Password",
                    passwordController,
                    Icons.lock,
                    obscure: true,
                    validator: validatePassword,
                  ),
                  const SizedBox(height: 12),
                  buildInputField(
                    "Number",
                    numberController,
                    Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: validateMobile,
                  ),
                  const SizedBox(height: 12),
                  buildInputField(
                    "Address",
                    addressController,
                    Icons.home,
                    validator: (val) => validateRequired(val, "Address"),
                  ),

                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Role",
                      border: OutlineInputBorder(),
                    ),
                    value: selectedRole,
                    items: ['user', 'admin'].map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role[0].toUpperCase() + role.substring(1)),
                      );
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
                          username: usernameController.text,
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
                          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("User Created ✅")),
                          );
                        } else {
                          await repo.updateUser(user);
                          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("User Updated ✏️")),
                          );
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                      child: Text(widget.user == null ? 'Add User' : 'Update User'),
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

// Helper functions for validation
  String? validateEmail(String? val) {
    if (val == null || val.isEmpty) return "Enter Email";
    // Basic email regex
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(val)) return "Enter valid email";
    return null;
  }

  String? validatePassword(String? val) {
    if (val == null || val.isEmpty) return "Enter Password";
    if (val.length < 6) return "Password must be at least 6 characters";
    return null;
  }

  String? validateMobile(String? val) {
    if (val == null || val.isEmpty) return "Enter Mobile Number";
    final digitOnly = RegExp(r'^\d{10}$');
    if (!digitOnly.hasMatch(val)) return "Mobile must be exactly 10 digits";
    return null;
  }

  String? validateRequired(String? val, String fieldName) {
    if (val == null || val.isEmpty) return "Enter $fieldName";
    return null;
  }

// Updated buildInputField with validator parameter
  Widget buildInputField(
      String label,
      TextEditingController controller,
      IconData icon, {
        bool obscure = false,
        String? Function(String?)? validator,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(),
      ),
      validator: validator ?? (val) => validateRequired(val, label),
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
