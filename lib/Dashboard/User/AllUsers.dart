
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
  List<UserModel> allUsers = [];
  List<UserModel> displayedUsers = [];

  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  String selectedStatus = 'All';

  bool _isLoading = false;

  int itemsPerPage = 10;
  int currentMaxIndex = 10;

  @override
  void initState() {
    super.initState();
    loadUsers();
    nameController.addListener(filterUsers);
    mobileController.addListener(filterUsers);
  }

  Future<void> loadUsers() async {
    setState(() => _isLoading = true);

    await userRepo.init();
    allUsers = await userRepo.getAllUsers();

    filterUsers();
  }

  void filterUsers() {
    setState(() => _isLoading = true);

    List<UserModel> filtered = allUsers.where((user) {
      final nameMatch = nameController.text.isEmpty ||
          user.shopName.toLowerCase().contains(nameController.text.toLowerCase());

      final mobileMatch = mobileController.text.isEmpty ||
          user.number.contains(mobileController.text);

      final statusMatch = selectedStatus == 'All' ||
          (user.status != null && user.status!.toLowerCase() == selectedStatus.toLowerCase());

      return nameMatch && mobileMatch && statusMatch;
    }).toList();

    setState(() {
      currentMaxIndex = itemsPerPage; // Reset pagination on new filter
      displayedUsers = filtered.take(currentMaxIndex).toList();
      _isLoading = false;
    });
  }

  void resetFilters() {
    nameController.clear();
    mobileController.clear();
    selectedStatus = 'All';
    loadUsers();
  }

  void showMore() {
    setState(() {
      currentMaxIndex += itemsPerPage;

      List<UserModel> filtered = allUsers.where((user) {
        final nameMatch = nameController.text.isEmpty ||
            user.shopName.toLowerCase().contains(nameController.text.toLowerCase());

        final mobileMatch = mobileController.text.isEmpty ||
            user.number.contains(mobileController.text);

        final statusMatch = selectedStatus == 'All' ||
            (user.status != null && user.status!.toLowerCase() == selectedStatus.toLowerCase());

        return nameMatch && mobileMatch && statusMatch;
      }).toList();

      if (currentMaxIndex > filtered.length) {
        currentMaxIndex = filtered.length;
      }
      displayedUsers = filtered.take(currentMaxIndex).toList();
    });
  }

  Future<void> deleteUser(int id) async {
    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await userRepo.init();
      await userRepo.deleteUser(id);  // Make sure your UserRepository has this method

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted ❌')),
      );
      loadUsers(); // Reload users after delete
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if more users can be shown
    List<UserModel> filteredUsers = allUsers.where((user) {
      final nameMatch = nameController.text.isEmpty ||
          user.shopName.toLowerCase().contains(nameController.text.toLowerCase());

      final mobileMatch = mobileController.text.isEmpty ||
          user.number.contains(mobileController.text);

      final statusMatch = selectedStatus == 'All' ||
          (user.status != null && user.status!.toLowerCase() == selectedStatus.toLowerCase());

      return nameMatch && mobileMatch && statusMatch;
    }).toList();

    bool canShowMore = displayedUsers.length < filteredUsers.length;

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
                                filterUsers();
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
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.end,
              //   children: [
              //     ElevatedButton.icon(
              //       icon: const Icon(Icons.download),
              //       label: const Text("Download Excel"),
              //       onPressed: exportUsersToCSV,
              //     ),
              //   ],
              // ),
              const SizedBox(height: 16),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : displayedUsers.isEmpty
                    ? const Center(child: Text('No data found'))
                    : SizedBox(
                  height: double.infinity,
                  child: SingleChildScrollView(
                        child: SingleChildScrollView(
                                          child: DataTable(
                        columns: const [
                          DataColumn(label: Text("Name")),
                          DataColumn(label: Text("Mobile")),
                          DataColumn(label: Text("Email")),
                          DataColumn(label: Text("Status")),
                          DataColumn(label: Text("Entry By")),
                          DataColumn(label: Text("Action")),
                        ],
                        rows: displayedUsers.map((user) {
                          return DataRow(cells: [
                            DataCell(Text(user.shopName)),
                            DataCell(Text(user.number)),
                            DataCell(Text(user.email)),
                            DataCell(Text(user.status ?? '')),
                            DataCell(Text(user.role)),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () async {
                                      await Navigator.pushNamed(context, '/addUser', arguments: user);
                                      loadUsers();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => deleteUser(user.id!),
                                    tooltip: 'Delete User',
                                  ),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                                          ),
                                        ),
                      ),
                    ),
              ),

              if (!_isLoading && canShowMore)
                ElevatedButton(
                  onPressed: showMore,
                  child: const Text("Show More"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
