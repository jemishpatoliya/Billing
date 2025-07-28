import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Bloc/nav_bloc.dart';

class Sidebar extends StatefulWidget {
  @override
  _SidebarState createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool _userExpanded = false;
  bool _masterExpanded = false;

  @override
  Widget build(BuildContext context) {
    final navCubit = context.read<NavCubit>();

    return Container(
      width: 240,
      color: Colors.grey[200],
      child: ListView(
        children: [
          DrawerHeader(
            child: Text('GO ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),

          // Dashboard
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            onTap: () => navCubit.changePage('dashboard'),
          ),

          // Users Section
          ExpansionTile(
            leading: Icon(Icons.people),
            title: Text('Users'),
            initiallyExpanded: _userExpanded,
            onExpansionChanged: (val) => setState(() => _userExpanded = val),
            children: [
              ListTile(
                leading: Icon(Icons.person_add),
                title: Text('Add User'),
                onTap: () => navCubit.changePage('add_user'),
              ),
              ListTile(
                leading: Icon(Icons.list),
                title: Text('All Users'),
                onTap: () => navCubit.changePage('all_users'),
              ),
            ],
          ),

          // Master Section
          ExpansionTile(
            leading: Icon(Icons.settings),
            title: Text('Master'),
            initiallyExpanded: _masterExpanded,
            onExpansionChanged: (val) => setState(() => _masterExpanded = val),
            children: [
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Customer'),
                onTap: () => navCubit.changePage('customer'),
              ),
              ListTile(
                leading: Icon(Icons.local_shipping),
                title: Text('Supplier'),
                onTap: () => navCubit.changePage('supplier'),
              ),
              ListTile(
                leading: Icon(Icons.groups),
                title: Text('App Parties'),
                onTap: () => navCubit.changePage('app_parties'),
              ),
              ListTile(
                leading: Icon(Icons.shopping_cart),
                title: Text('Product'),
                onTap: () => navCubit.changePage('product'),
              ),
              ListTile(
                leading: Icon(Icons.emoji_transportation),
                title: Text('Transport'),
                onTap: () => navCubit.changePage('transport'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
