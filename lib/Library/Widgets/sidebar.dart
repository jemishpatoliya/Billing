import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Bloc/nav_bloc.dart';
import '../UserSession.dart';

class Sidebar extends StatefulWidget {
  @override
  _SidebarState createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  final Map<String, bool> _expandedSections = {
    'users': false,
    'master': false,
    'quotations': false,
    'invoices': false,
    'purchases': false,
    'stock': false,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isAdmin = UserSession.loggedInUser?.role == 'admin';
    final navCubit = context.read<NavCubit>();

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - Made more compact
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), // Reduced padding
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_circle, size: 28, color: theme.primaryColor), // Smaller icon
                  const SizedBox(width: 8), // Reduced spacing
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoxel',
                        style: theme.textTheme.titleMedium?.copyWith( // Smaller font
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      Text(
                        UserSession.loggedInUser?.email ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 12), // Smaller font
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Menu Items - Removed extra padding
            Column(
              children: [
                // Dashboard - No extra spacing
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  onTap: () => navCubit.changePage('dashboard'),
                ),

                // Users Section (Admin only)
                if (isAdmin)
                  _buildExpansionTile(
                    context,
                    icon: Icons.people_outlined,
                    title: 'User Management',
                    isExpanded: _expandedSections['users']!,
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.person_add_outlined,
                        title: 'Add User',
                        onTap: () => navCubit.changePage('add_user'),
                        isNested: true,
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.list_outlined,
                        title: 'All Users',
                        onTap: () => navCubit.changePage('all_users'),
                        isNested: true,
                      ),
                    ],
                    onExpansionChanged: (val) => setState(() => _expandedSections['users'] = val),
                  ),

                // Master Section
                _buildExpansionTile(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Master Data',
                  isExpanded: _expandedSections['master']!,
                  children: [
                    if (UserSession.canView('Customer'))
                      _buildMenuItem(
                        context,
                        icon: Icons.person_outlined,
                        title: 'Customers',
                        onTap: () => navCubit.changePage('customer'),
                        isNested: true,
                      ),
                    _buildMenuItem(
                      context,
                      icon: Icons.local_shipping_outlined,
                      title: 'Suppliers',
                      onTap: () => navCubit.changePage('supplier'),
                      isNested: true,
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.group_outlined,
                      title: 'App Parties',
                      onTap: () => navCubit.changePage('app_parties'),
                      isNested: true,
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.shopping_bag_outlined,
                      title: 'Products',
                      onTap: () => navCubit.changePage('product'),
                      isNested: true,
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.directions_bus_outlined,
                      title: 'Transport',
                      onTap: () => navCubit.changePage('transport'),
                      isNested: true,
                    ),
                  ],
                  onExpansionChanged: (val) => setState(() => _expandedSections['master'] = val),
                ),

                // Quotations
                _buildExpansionTile(
                  context,
                  icon: Icons.request_quote_outlined,
                  title: 'Quotations',
                  isExpanded: _expandedSections['quotations']!,
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.note_add_outlined,
                      title: 'Add Quotation',
                      onTap: () => navCubit.changePage('add_quotation'),
                      isNested: true,
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.list_alt_outlined,
                      title: 'All Quotations',
                      onTap: () => navCubit.changePage('all_quotations'),
                      isNested: true,
                    ),
                  ],
                  onExpansionChanged: (val) => setState(() => _expandedSections['quotations'] = val),
                ),

                // Invoices
                if (UserSession.canView('Invoice'))
                  _buildExpansionTile(
                    context,
                    icon: Icons.receipt_long_outlined,
                    title: 'Invoices',
                    isExpanded: _expandedSections['invoices']!,
                    children: [
                      if (UserSession.canCreate('Invoice'))
                        _buildMenuItem(
                          context,
                          icon: Icons.note_add_outlined,
                          title: 'Add Invoice',
                          onTap: () => navCubit.changePage('add_invoice'),
                          isNested: true,
                        ),
                      _buildMenuItem(
                        context,
                        icon: Icons.list_outlined,
                        title: 'All Invoices',
                        onTap: () => navCubit.changePage('all_invoice'),
                        isNested: true,
                      ),
                    ],
                    onExpansionChanged: (val) => setState(() => _expandedSections['invoices'] = val),
                  ),

                // Purchases
                _buildExpansionTile(
                  context,
                  icon: Icons.shopping_cart_outlined,
                  title: 'Purchases',
                  isExpanded: _expandedSections['purchases']!,
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.add_shopping_cart_outlined,
                      title: 'Add Purchase',
                      onTap: () => navCubit.changePage('add_purchase'),
                      isNested: true,
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.list_alt_outlined,
                      title: 'All Purchases',
                      onTap: () => navCubit.changePage('purchaseList'),
                      isNested: true,
                    ),
                  ],
                  onExpansionChanged: (val) => setState(() => _expandedSections['purchases'] = val),
                ),
                
                // Stock Management
                _buildExpansionTile(
                  context,
                  icon: Icons.inventory_outlined,
                  title: 'Stock Management',
                  isExpanded: _expandedSections['stock']!,
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.assessment_outlined,
                      title: 'Stock Overview',
                      onTap: () => navCubit.changePage('stock_management'),
                      isNested: true,
                    ),
                  ],
                  onExpansionChanged: (val) => setState(() => _expandedSections['stock'] = val),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        bool isNested = false,
        bool isSelected = false,
      }) {
    final theme = Theme.of(context);

    return Container(
      margin: isNested ? const EdgeInsets.only(left: 16) : null, // Reduced indentation
      child: ListTile(
        dense: true,
        minVerticalPadding: 8, // Reduced padding
        contentPadding: const EdgeInsets.symmetric(horizontal: 12), // Compact padding
        leading: Icon(
          icon,
          size: 20, // Smaller icon
          color: isSelected ? theme.primaryColor : theme.iconTheme.color,
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14, // Smaller font
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? theme.primaryColor : null,
          ),
        ),
        onTap: onTap,
        horizontalTitleGap: 4,
        minLeadingWidth: 20, // Reduced leading width
      ),
    );
  }

  Widget _buildExpansionTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required bool isExpanded,
        required List<Widget> children,
        required Function(bool) onExpansionChanged,
      }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 4), // Reduced spacing between sections
      decoration: BoxDecoration(
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(6), // Smaller radius
      ),
      child: Theme(
        data: theme.copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          leading: Icon(
            icon,
            size: 20, // Smaller icon
            color: theme.iconTheme.color,
          ),
          title: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14, // Smaller font
              fontWeight: FontWeight.w600,
            ),
          ),
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpansionChanged,
          children: children,
          tilePadding: const EdgeInsets.symmetric(horizontal: 8), // Compact padding
          collapsedIconColor: theme.iconTheme.color,
          iconColor: theme.iconTheme.color,
          childrenPadding: EdgeInsets.zero, // Remove children padding
        ),
      ),
    );
  }
}