import 'package:flutter/material.dart';

import '../../Database/UserRepository.dart';
import '../../Model/UserModel.dart';

class Allusers extends StatefulWidget {
  const Allusers({super.key});

  @override
  State<Allusers> createState() => _AllusersState();
}

class _AllusersState extends State<Allusers> {
  final userRepo = UserRepository();
  List<UserModel> users = [];

  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  String selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    loadUsers();
    nameController.addListener(filterUsers);
    mobileController.addListener(filterUsers);
  }

  bool _isLoading = false;

  Future<void> loadUsers() async {
    await userRepo.init();
    final allUsers = await userRepo.getAllUsers();
    setState(() {
      users = allUsers;
    });
  }

  void filterUsers() async {
    setState(() => _isLoading = true);

    await userRepo.init();
    List<UserModel> allUsers = await userRepo.getAllUsers();

    setState(() {
      users = allUsers.where((user) {
        final nameMatch = nameController.text.isEmpty ||
            user.shopName.toLowerCase().contains(nameController.text.toLowerCase());

        final mobileMatch = mobileController.text.isEmpty ||
            user.number.contains(mobileController.text);

        final statusMatch = selectedStatus == 'All' ||
            (user.status != null && user.status!.toLowerCase() == selectedStatus.toLowerCase());

        return nameMatch && mobileMatch && statusMatch;
      }).toList();
      _isLoading = false;
    });
  }

  void resetFilters() {
    nameController.clear();
    mobileController.clear();
    selectedStatus = 'All';
    loadUsers();  // will load all again
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Users')),
      body: RefreshIndicator(
        onRefresh: loadUsers,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Search", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: "Name",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: mobileController,
                              decoration: const InputDecoration(
                                labelText: "Mobile",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedStatus,
                              items: ['All', 'Active', 'Inactive']
                                  .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ))
                                  .toList(),
                              decoration: const InputDecoration(
                                labelText: "Status",
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  selectedStatus = val!;
                                });
                                filterUsers(); // 🔁 Immediately filter when status changes
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: filterUsers,
                            child: const Text("Search"),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: resetFilters,
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text("Reset"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 📄 User List Section
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : users.isEmpty
                    ? const Center(child: Text('No data found'))
                    : SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("Name")),
                      DataColumn(label: Text("Mobile")),
                      DataColumn(label: Text("Email")),
                      DataColumn(label: Text("Status")),
                      DataColumn(label: Text("Entry By")),
                      DataColumn(label: Text("Action")),
                    ],
                    rows: users.map((user) {
                      return DataRow(cells: [
                        DataCell(Text(user.shopName)),
                        DataCell(Text(user.number)),
                        DataCell(Text(user.email)),
                        DataCell(Text(user.status??'')),
                        DataCell(Text(user.role)),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () async {
                              await Navigator.pushNamed(context, '/addUser', arguments: user);
                              loadUsers();
                            },
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
