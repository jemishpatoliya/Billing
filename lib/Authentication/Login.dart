import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../BLoC/LoginBloc.dart';
import '../Dashboard/Dashboard.dart';
import '../Database/UserRepository.dart';

class Login extends StatefulWidget {
  final UserRepository repository;
  const Login({required this.repository, super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late LoginBloc _loginBloc;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loginBloc = LoginBloc(widget.repository);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return BlocProvider.value(
      value: _loginBloc,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDarkMode
                  ? [Colors.grey[900]!, Colors.grey[800]!]
                  : [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: isLargeScreen ? 500 : double.infinity,
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: BlocConsumer<LoginBloc, LoginState>(
                    listener: (context, state) {
                      if (state is LoginSuccess) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => Dashboard()),
                        );
                      } else if (state is LoginFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.error),
                            backgroundColor: Colors.red[400],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            Icons.account_circle,
                            size: 72,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Welcome Back",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.grey[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Sign in to continue",
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          _buildTextField(
                            context,
                            controller: emailController,
                            label: "Email Address",
                            icon: Icons.email_outlined,
                            inputType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$');
                              if (!emailRegex.hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            context,
                            controller: passwordController,
                            label: "Password",
                            icon: Icons.lock_outlined,
                            obscure: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // TODO: Implement forgot password
                              },
                              child: Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          state is LoginLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _loginBloc.add(
                                  SubmitLoginEvent(
                                    emailController.text.trim(),
                                    passwordController.text.trim(),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "LOGIN",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account?",
                                style: TextStyle(
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 4),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/register');
                                },
                                child: Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      BuildContext context, {
        required TextEditingController controller,
        required String label,
        required IconData icon,
        bool obscure = false,
        TextInputType inputType = TextInputType.text,
        Widget? suffixIcon,
        String? Function(String?)? validator,
      }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: inputType,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.grey[800],
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
        prefixIcon: Icon(
          icon,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        errorStyle: const TextStyle(
          fontSize: 12,
        ),
      ),
      validator: validator,
    );
  }
}