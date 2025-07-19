import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'Authentication/Register.dart';
import 'Authentication/Login.dart';
import 'Bloc/RegisterBloc.dart';
import 'Database/UserRepository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final userRepo = UserRepository();
  await userRepo.init(); // Initialize SQLite

  runApp(MyApp(userRepo));
}

class MyApp extends StatelessWidget {
  final UserRepository userRepo;

  MyApp(this.userRepo);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => RegisterBloc(userRepo)),
        // You can add LoginBloc here if needed
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Routing Demo',
        initialRoute: '/login',
        routes: {
          '/register': (context) => Register(repository: userRepo),
          '/login': (context) => Login(repository: userRepo),
          // Add more routes if needed
        },
      ),
    );
  }
}
