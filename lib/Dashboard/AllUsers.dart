import 'package:flutter/material.dart';
import '../Database/UserRepository.dart';
import '../Model/UserModel.dart';

class Allusers extends StatefulWidget {
  const Allusers({super.key});

  @override
  State<Allusers> createState() => _AllusersState();
}

class _AllusersState extends State<Allusers> {
  final userRepo = UserRepository();
  List<UserModel> users = [];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    await userRepo.init();
    final allUsers = await userRepo.getAllUsers();
    setState(() {
      users = allUsers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Users')),
      body: RefreshIndicator(
        onRefresh: loadUsers,
        child: users.isEmpty
            ? const Center(child: Text('No users found'))
            : ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: CircleAvatar(child: Text(user.shopName[0])),
                title: Text(user.shopName),
                subtitle: Text("Email: ${user.email}\nRole: ${user.role}"),
                isThreeLine: true,
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("Status: ${user.status}"),
                    Text("Number: ${user.number}"),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        await Navigator.pushNamed(
                          context,
                          '/addUser',
                          arguments: user, // Pass user for editing
                        );
                        loadUsers(); // Refresh list after return
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
