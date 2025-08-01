import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'Authentication/Register.dart';
import 'Authentication/Login.dart';
import 'Bloc/RegisterBloc.dart';
import 'Bloc/nav_bloc.dart';
import 'Dashboard/Quotation/AddQuotation.dart';
import 'Dashboard/User/AddUser.dart';
import 'Dashboard/Dashboard.dart';
import 'Database/UserRepository.dart';
import 'Library/Widgets/sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Model/UserModel.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final userRepo = UserRepository();
  await userRepo.init(); // Initialize SQLite

  final prefs = await SharedPreferences.getInstance();
  final loggedInEmail = prefs.getString('loggedInEmail');

  bool isLoggedIn = false;

  if (loggedInEmail != null) {
    final existingUser = await userRepo.getUserByEmail(loggedInEmail);
    if (existingUser != null) {
      isLoggedIn = true;
    } else {
      // 👇 Remove stale email if user is deleted from DB
      await prefs.remove('loggedInEmail');
    }
  }

  runApp(MyApp(userRepo, loggedInEmail != null));
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