import 'package:Invoxel/Dashboard/Purchase/AddPurchase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Invoxel/Dashboard/Quotation/AddQuotation.dart';
import '../Bloc/nav_bloc.dart';
import '../Library/Widgets/Topbar.dart';
import '../Library/Widgets/sidebar.dart';
import 'Invoice/AddInvoice.dart';
import 'Invoice/AllInvoice.dart';
import 'Master/Customer.dart';
import 'Master/Product.dart';
import 'Master/Transport.dart';
import 'Purchase/PurchaseList.dart';
import 'User/AddUser.dart';
import 'User/AllUsers.dart';

class Dashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sidebar with fixed width
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 260),
              child: Sidebar(),
            ),

            // Main content area
            Expanded(
              child: Column(
                children: [
                  // Topbar with fixed height
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 64),
                    child: Topbar(),
                  ),

                  // Main content with proper spacing
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: BlocBuilder<NavCubit, String>(
                        builder: (context, state) {
                          return AnimatedSwitcher(
                            duration: Duration(milliseconds: 300),
                            child: _buildPageContent(state, context),
                          );
                        },
                      ),
                    ),
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(String state, BuildContext context) {
    switch (state) {
      case 'transport':
        return AddTransport(key: ValueKey('transport'));
      case 'customer':
        return CustomerList(key: ValueKey('customer'));
      case 'all_users':
        return AllUsers(key: ValueKey('all_users'));
      case 'add_user':
        return AddUsers(key: ValueKey('add_user'));
      // case 'add_quotation':
      //   return AddQuotation(key: ValueKey('add_quotation'));
      case 'add_invoice':
        return AddInvoice(key: ValueKey('add_invoice'));
      case 'all_invoice':
        return InvoiceList(key: ValueKey('all_invoice'));
      case 'product':
        return ProductList(key: ValueKey('product'));
      case 'add_purchase':
        return AddPurchase(key: ValueKey('add_purchase'));
        case 'purchaseList':
        return PurchaseList(key: ValueKey('purchaseList'));
      default:
        return _buildDefaultDashboard(context);
    }
  }

  Widget _buildDefaultDashboard(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard,
            size: 72,
            color: theme.primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Invoxel',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select an option from the sidebar to begin',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}