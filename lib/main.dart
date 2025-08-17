import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'Authentication/Register.dart';
import 'Authentication/Login.dart';
import 'Bloc/RegisterBloc.dart';
import 'Bloc/nav_bloc.dart';
import 'Dashboard/Purchase/PurchaseList.dart';
import 'Dashboard/Quotation/AddQuotation.dart';
import 'Dashboard/User/AddUser.dart';
import 'Dashboard/Dashboard.dart';
import 'Database/UserRepository.dart';
import 'Library/UserSession.dart';
import 'Library/Widgets/sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Model/UserModel.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final userRepo = UserRepository();
  await userRepo.init(); // Initialize SQLite

  final prefs = await SharedPreferences.getInstance();

  // Restore user session from JSON if saved
  final userJson = prefs.getString('loggedInUserJson');
  if (userJson != null) {
    UserModel user = UserModel.fromJson(jsonDecode(userJson));
    UserSession.setLoggedInUser(user);
  }

  final loggedInEmail = prefs.getString('loggedInEmail');

  bool isLoggedIn = false;

  if (loggedInEmail != null) {
    final existingUser = await userRepo.getUserByEmail(loggedInEmail);
    if (existingUser != null) {
      isLoggedIn = true;

      // If you want, also update UserSession here with fresh DB data
      UserSession.setLoggedInUser(existingUser);
    } else {
      await prefs.remove('loggedInEmail');
      await prefs.remove('loggedInUserJson'); // clear stale JSON also
    }
  }
  runApp(MyApp(userRepo, isLoggedIn));
}


class MyApp extends StatelessWidget {
  final UserRepository userRepo;
  final bool isLoggedIn;


  MyApp(this.userRepo,this.isLoggedIn);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => RegisterBloc(userRepo)),
        BlocProvider(create: (_) => NavCubit()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Routing Demo',
        initialRoute: isLoggedIn ? '/' : '/login',
        routes: {
          '/': (context) => Dashboard(), // Sidebar with navigation
          '/register': (context) => Register(repository: userRepo),
          '/login': (context) => Login(repository: userRepo),
          '/dashboard': (context) => Dashboard(),
          '/addQuotation': (context) => AddQuotation(),
          '/addUser': (context) {
            final user = ModalRoute.of(context)!.settings.arguments as UserModel?;
            return AddUsers(user: user);
          },
        },
      ),
    );
  }
}