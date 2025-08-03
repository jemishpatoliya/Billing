import 'package:flutter/material.dart';
import '../../Database/UserRepository.dart';
import '../../Model/UserModel.dart';

class AllUsers extends StatefulWidget {
  const AllUsers({super.key});

  @override
  State<AllUsers> createState() => _AllUsersState();
}

class _AllUsersState extends State<AllUsers> {
  final userRepo = UserRepository();
  List<UserModel> allUsers = [];
  List<UserModel> displayedUsers = [];
  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  String selectedStatus = 'All';
  bool _isLoading = false;
  int itemsPerPage = 10;
  int currentMaxIndex = 10;
  String _sortColumn = 'name';
  bool _sortAscending = true;

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
    _sortUsers();
    filterUsers();
  }

  void _sortUsers() {
    allUsers.sort((a, b) {
      var aValue, bValue;
      switch (_sortColumn) {
        case 'name':
          aValue = a.shopName.toLowerCase();
          bValue = b.shopName.toLowerCase();
          break;
        case 'mobile':
          aValue = a.number;
          bValue = b.number;
          break;
        case 'status':
          aValue = a.status ?? '';
          bValue = b.status ?? '';
          break;
        default:
          aValue = a.shopName.toLowerCase();
          bValue = b.shopName.toLowerCase();
      }

      if (aValue == bValue) return 0;
      return _sortAscending
          ? aValue.compareTo(bValue)
          : bValue.compareTo(aValue);
    });
  }

  void filterUsers() {
    setState(() {
      displayedUsers = allUsers.where((user) {
        final nameMatch = nameController.text.isEmpty ||
            user.shopName.toLowerCase().contains(nameController.text.toLowerCase());
        final mobileMatch = mobileController.text.isEmpty ||
            user.number.contains(mobileController.text);
        final statusMatch = selectedStatus == 'All' ||
            (user.status != null && user.status!.toLowerCase() == selectedStatus.toLowerCase());
        return nameMatch && mobileMatch && statusMatch;
      }).take(currentMaxIndex).toList();
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
      filterUsers();
    });
  }

  Future<void> deleteUser(int id) async {
    final confirm = await showDialog<bool>(
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
      await userRepo.deleteUser(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User deleted successfully'),
          backgroundColor: Colors.red[400],
        ),
      );
      loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canShowMore = currentMaxIndex < allUsers.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadUsers,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Search Users",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nameController,
                              decoration: InputDecoration(
                                labelText: "Name",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: mobileController,
                              decoration: InputDecoration(
                                labelText: "Mobile",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedStatus,
                              items: ['All', 'Active', 'Inactive']
                                  .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ))
                                  .toList(),
                              decoration: InputDecoration(
                                labelText: "Status",
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                              ),
                              onChanged: (val) {
                                setState(() => selectedStatus = val!);
                                filterUsers();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            icon: Icon(Icons.clear, size: 18),
                            label: Text("Reset"),
                            onPressed: resetFilters,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: Icon(Icons.search, size: 18),
                            label: Text("Search"),
                            onPressed: filterUsers,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : displayedUsers.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_alt, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        "No users found",
                        style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
                      ),
                      if (nameController.text.isNotEmpty ||
                          mobileController.text.isNotEmpty ||
                          selectedStatus != 'All')
                        TextButton(
                          onPressed: resetFilters,
                          child: Text("Clear search filters"),
                        ),
                    ],
                  ),
                )
                    : Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.resolveWith<Color>(
                              (states) => theme.colorScheme.primary.withOpacity(0.05),
                        ),
                        columns: [
                          DataColumn(
                            label: Text("Name"),
                            onSort: (columnIndex, ascending) {
                              setState(() {
                                _sortColumn = 'name';
                                _sortAscending = ascending;
                                _sortUsers();
                                filterUsers();
                              });
                            },
                          ),
                          DataColumn(
                            label: Text("Mobile"),
                            onSort: (columnIndex, ascending) {
                              setState(() {
                                _sortColumn = 'mobile';
                                _sortAscending = ascending;
                                _sortUsers();
                                filterUsers();
                              });
                            },
                          ),
                          DataColumn(label: Text("Email")),
                          DataColumn(
                            label: Text("Status"),
                            onSort: (columnIndex, ascending) {
                              setState(() {
                                _sortColumn = 'status';
                                _sortAscending = ascending;
                                _sortUsers();
                                filterUsers();
                              });
                            },
                          ),
                          DataColumn(label: Text("Entry By")),
                          DataColumn(label: Text("Actions")),
                        ],
                        rows: displayedUsers.map((user) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  user.shopName,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              DataCell(Text(user.number)),
                              DataCell(
                                Text(
                                  user.email,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DataCell(
                                Chip(
                                  label: Text(
                                    user.status ?? 'N/A',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: user.status?.toLowerCase() == 'active'
                                      ? Colors.green
                                      : Colors.orange,
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                              ),
                              DataCell(Text(user.role)),
                              DataCell(
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: 100),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit, size: 20, color: Colors.blue),
                                        onPressed: () async {
                                          await Navigator.pushNamed(context, '/addUser', arguments: user);
                                          loadUsers();
                                        },
                                        padding: EdgeInsets.zero,
                                        tooltip: 'Edit User',
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, size: 20, color: Colors.red),
                                        onPressed: () => deleteUser(user.id!),
                                        padding: EdgeInsets.zero,
                                        tooltip: 'Delete User',
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              if (!_isLoading && canShowMore)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton(
                    onPressed: showMore,
                    child: Text("Load More (${allUsers.length - currentMaxIndex} remaining)"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.add),
        label: Text("Add User"),
        onPressed: () async {
          await Navigator.pushNamed(context, '/addUser');
          loadUsers();
        },
        elevation: 4,
      ),
    );
  }
}