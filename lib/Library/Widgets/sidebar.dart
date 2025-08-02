import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Bloc/nav_bloc.dart';
import '../UserSession.dart';

class Sidebar extends StatefulWidget {
  @override
  _SidebarState createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool _userExpanded = false;
  bool _masterExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isAdmin = UserSession.loggedInUser?.role == 'admin'; // or your admin role identifier
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
          Visibility(
            visible: isAdmin,
            child: ExpansionTile(
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
          ),

          // Master Section
          ExpansionTile(
            leading: Icon(Icons.settings),
            title: Text('Master'),
            initiallyExpanded: _masterExpanded,
            onExpansionChanged: (val) => setState(() => _masterExpanded = val),
            children: [
              Visibility(
                visible: UserSession.canCreate('Customer') || UserSession.canView('Customer') || UserSession.canEdit('Customer'),
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Customer'),
                  onTap: () => navCubit.changePage('customer'),
                ),
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
          // Add this after the "Master" section in your ListView

// Quotation Section
          ExpansionTile(
            leading: Icon(Icons.request_quote),
            title: Text('Quotations'),
            children: [
              ListTile(
                leading: Icon(Icons.note_add),
                title: Text('Add Quotation'),
                onTap: () => navCubit.changePage('add_quotation'),
              ),
              ListTile(
                leading: Icon(Icons.list_alt),
                title: Text('All Quotations'),
                onTap: () => navCubit.changePage('all_quotations'),
              ),
            ],
          ),
          Visibility(
            visible: UserSession.canCreate('Invoice') || UserSession.canView('Invoice') || UserSession.canEdit('Invoice'),
            child: ExpansionTile(
              leading: Icon(Icons.receipt_long),
              title: Text('Invoices'),
              children: [
                Visibility(
                  visible: UserSession.canCreate('Invoice') || UserSession.canEdit('Invoice'),
                  child: ListTile(
                    leading: Icon(Icons.note_add_outlined),
                    title: Text('Add Invoice'),
                    onTap: () => navCubit.changePage('add_invoice'),
                  ),
                ),
                Visibility(
                  visible: UserSession.canView('Invoice'),
                  child: ListTile(
                    leading: Icon(Icons.list),
                    title: Text('All Invoices'),
                    onTap: () => navCubit.changePage('all_invoice'),
                  ),
                ),
              ],
            ),
          ),

          // Purchase Section
          ExpansionTile(
            leading: Icon(Icons.shopping_bag),
            title: Text('Purchases'),
            children: [
              ListTile(
                leading: Icon(Icons.add_shopping_cart),
                title: Text('Add Purchase'),
                onTap: () => navCubit.changePage('add_purchase'),
              ),
              ListTile(
                leading: Icon(Icons.list_alt_outlined),
                title: Text('All Purchases'),
                onTap: () => navCubit.changePage('all_purchases'),
              ),
            ],
          ),

        ],
      ),
    );
  }
}
