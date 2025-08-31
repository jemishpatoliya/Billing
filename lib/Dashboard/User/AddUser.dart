
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
    _initializePermissions();
    _loadExistingUserData();
  }

  void _initializePermissions() {
    for (var module in modules) {
      permissions[module] = {
        'View': false,
        'Create': false,
        'Edit': false,
      };
    }
  }

  void _loadExistingUserData() {
    final existingUser = widget.user;
    if (existingUser != null) {
      emailController.text = existingUser.email;
      passwordController.text = existingUser.password;
      numberController.text = existingUser.number;
      addressController.text = existingUser.address;
      usernameController.text = existingUser.username ?? '';

      selectedRole = _validateRole(existingUser.role);
      selectedStatus = _validateStatus(existingUser.status);

      try {
        final decodedPermissions = jsonDecode(existingUser.permissions ?? '{}');
        _loadPermissions(decodedPermissions);
      } catch (e) {
        debugPrint("Permission decode error: $e");
      }
    }
  }

  String _validateRole(String? role) {
    final normalizedRole = role?.trim().toLowerCase() ?? 'user';
    return ['admin', 'user'].contains(normalizedRole) ? normalizedRole : 'user';
  }

  String _validateStatus(String? status) {
    return ['Active', 'Inactive'].contains(status) ? status! : 'Active';
  }

  void _loadPermissions(Map<String, dynamic> decodedPermissions) {
    for (var module in decodedPermissions.keys) {
      if (permissions.containsKey(module)) {
        final modulePerms = decodedPermissions[module] as Map<String, dynamic>;
        for (var action in modulePerms.keys) {
          if (permissions[module]!.containsKey(action)) {
            permissions[module]![action] = modulePerms[action] == true;
          }
        }
      }
    }
    selectAll = permissions.values.every(
          (perm) => perm.values.every((val) => val == true),
    );
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
      selectAll = permissions.values.every(
              (actionMap) => actionMap.values.every((val) => val == true)
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user == null ? "Add New User" : "Edit User"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            "Basic Information",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            "User Name",
                            usernameController,
                            Icons.person_outline,
                            validator: (val) => _validateRequired(val, "User Name"),
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            "Email",
                            emailController,
                            Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            "Password",
                            passwordController,
                            Icons.lock_outline,
                            obscure: true,
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            "Phone Number",
                            numberController,
                            Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: _validateMobile,
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            "Address",
                            addressController,
                            Icons.home_outlined,
                            maxLines: 2,
                            validator: (val) => _validateRequired(val, "Address"),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "User Settings",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdown(
                                  "Role",
                                  selectedRole,
                                  ['user', 'admin'],
                                      (val) => setState(() => selectedRole = val!),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDropdown(
                                  "Status",
                                  selectedStatus,
                                  ['Active', 'Inactive'],
                                      (val) => setState(() => selectedStatus = val!),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Permissions",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                              Row(
                                children: [
                                  const Text("Select All"),
                                  const SizedBox(width: 8),
                                  Switch(
                                    value: selectAll,
                                    onChanged: toggleSelectAll,
                                    activeColor: theme.primaryColor,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _buildPermissionTable(theme, isDarkMode),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: _saveUser,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        widget.user == null ? 'CREATE USER' : 'UPDATE USER',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
      String label,
      TextEditingController controller,
      IconData icon, {
        bool obscure = false,
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown(
      String label,
      String value,
      List<String> items,
      Function(String?) onChanged,
      ) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
      ),
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item[0].toUpperCase() + item.substring(1)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildPermissionTable(ThemeData theme, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DataTable(
        headingRowColor: MaterialStateProperty.resolveWith<Color>(
              (states) => isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
        ),
        columns: const [
          DataColumn(label: Text('Module', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('View', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Create', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Edit', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: modules.map((module) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  module,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              DataCell(
                Center(
                  child: Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: permissions[module]!['View'],
                      onChanged: (val) => togglePermission(module, 'View', val),
                      fillColor: MaterialStateProperty.resolveWith<Color>(
                            (states) => states.contains(MaterialState.selected)
                            ? theme.primaryColor
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              DataCell(
                Center(
                  child: Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: permissions[module]!['Create'],
                      onChanged: (val) => togglePermission(module, 'Create', val),
                      fillColor: MaterialStateProperty.resolveWith<Color>(
                            (states) => states.contains(MaterialState.selected)
                            ? theme.primaryColor
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              DataCell(
                Center(
                  child: Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: permissions[module]!['Edit'],
                      onChanged: (val) => togglePermission(module, 'Edit', val),
                      fillColor: MaterialStateProperty.resolveWith<Color>(
                            (states) => states.contains(MaterialState.selected)
                            ? theme.primaryColor
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      final user = UserModel(
        id: widget.user?.id,
        shopName: usernameController.text,
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

      final successMessage = widget.user == null
          ? "User created successfully"
          : "User updated successfully";

      try {
        if (widget.user == null) {
          await repo.registerUser(user);
        } else {
          await repo.updateUser(user);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Validation methods
  String? _validateEmail(String? val) {
    if (val == null || val.isEmpty) return "Email is required";
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(val)) return "Enter a valid email address";
    return null;
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) return "Password is required";
    if (val.length < 6) return "Password must be at least 6 characters";
    return null;
  }

  String? _validateMobile(String? val) {
    if (val == null || val.isEmpty) return "Phone number is required";
    final digitOnly = RegExp(r'^\d{10}$');
    if (!digitOnly.hasMatch(val)) return "Enter a valid 10-digit phone number";
    return null;
  }

  String? _validateRequired(String? val, String fieldName) {
    if (val == null || val.isEmpty) return "$fieldName is required";
    return null;
  }
}