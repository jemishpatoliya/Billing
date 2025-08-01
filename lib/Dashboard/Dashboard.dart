import 'package:Invoxel/Dashboard/Quotation/AddQuotation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Bloc/nav_bloc.dart';
import '../Library/Widgets/Topbar.dart';
import '../Library/Widgets/sidebar.dart';
import 'Invoice/AddInvoice.dart';
import 'User/AddUser.dart';
import 'Customer.dart';
import 'TransportPage.dart';
import 'User/AllUsers.dart';


class Dashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(), // Left panel
          Expanded(
            child: Column(
              children: [
                Topbar(), // Top bar
                Expanded(
                  child: BlocBuilder<NavCubit, String>(
                    builder: (context, state) {
                      switch (state) {
                        case 'transport':
                          return TransportPage();
                        case 'customer':
                          return Customers();
                        // case 'supplier':
                        //   return SupplierPage();
                        // case 'app_parties':
                        //   return AppPartiesPage();
                        // case 'product':
                        //   return ProductPage();
                        case 'all_users':
                          return Allusers();
                        case 'add_user':
                          return AddUsers();
                        case 'add_quotation':
                          return AddQuotation();
                        case 'add_invoice':
                          return AddInvoice();
                        default:
                          return Center(
                            child: Text(
                              'Welcome to Dashboard',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
