import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'Authentication/Register.dart';
import 'Bloc/RegisterBloc.dart';
import 'Database/UserRepository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final userRepo = UserRepository();
  await userRepo.init(); // initialize SQLite

  runApp(MyApp(userRepo));
}

class MyApp extends StatelessWidget {
  final UserRepository userRepo;

  MyApp(this.userRepo);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Register Demo',
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
        create: (_) => RegisterBloc(userRepo),
        child: RegisterScreen(),
      ),
    );
  }
}
