import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Bloc/RegisterBloc.dart';
import '../Database/UserRepository.dart';
import '../Model/UserModel.dart';
import 'Login.dart';

class Register extends StatefulWidget {
  final UserRepository repository;
  const Register({required this.repository, Key? key}) : super(key: key);

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final shopController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();
  final numberController = TextEditingController();
  final passController = TextEditingController();
  final confirmController = TextEditingController();
  final userNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
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
              width: isLargeScreen ? 600 : double.infinity,
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
              child: BlocConsumer<RegisterBloc, RegisterState>(
                listener: (context, state) {
                  if (state is RegisterSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("🎉 Registration successful!"),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    _clearForm();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => Login(repository: widget.repository)),
                    );
                  } else if (state is RegisterFailure) {
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
                  return Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.person_add_alt_1,
                          size: 72,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : Colors.grey[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Fill in your details to get started",
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        _buildTextField(
                          context,
                          controller: shopController,
                          label: "Shop Name",
                          icon: Icons.store_outlined,
                          validator: (value) => _validateRequired(value, "Shop Name"),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          context,
                          controller: userNameController,
                          label: "Username",
                          icon: Icons.person_outline,
                          validator: (value) => _validateRequired(value, "Username"),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          context,
                          controller: addressController,
                          label: "Address",
                          icon: Icons.location_on_outlined,
                          validator: (value) => _validateRequired(value, "Address"),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          context,
                          controller: emailController,
                          label: "Email Address",
                          icon: Icons.email_outlined,
                          inputType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          context,
                          controller: numberController,
                          label: "Mobile Number",
                          icon: Icons.phone_outlined,
                          inputType: TextInputType.phone,
                          validator: _validateMobile,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          context,
                          controller: passController,
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
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          context,
                          controller: confirmController,
                          label: "Confirm Password",
                          icon: Icons.lock_outline,
                          obscure: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          validator: _validateConfirmPassword,
                        ),
                        const SizedBox(height: 24),
                        state is RegisterLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "REGISTER",
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
                              "Already have an account?",
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 4),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => Login(repository: widget.repository)),
                                );
                              },
                              child: Text(
                                "Sign In",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
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

  void _clearForm() {
    shopController.clear();
    addressController.clear();
    emailController.clear();
    numberController.clear();
    userNameController.clear();
    passController.clear();
    confirmController.clear();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (passController.text != confirmController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Passwords do not match"),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }

      final user = UserModel(
        username: userNameController.text,
        shopName: shopController.text,
        address: addressController.text,
        email: emailController.text,
        number: numberController.text,
        password: passController.text,
        role: 'admin',
      );
      context.read<RegisterBloc>().add(SubmitRegisterEvent(user));
    }
  }

  // Validation methods
  String? _validateRequired(String? val, String fieldName) {
    if (val == null || val.isEmpty) return "$fieldName is required";
    return null;
  }

  String? _validateEmail(String? val) {
    if (val == null || val.isEmpty) return "Email is required";
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$');
    if (!emailRegex.hasMatch(val)) return "Enter a valid email address";
    return null;
  }

  String? _validateMobile(String? val) {
    if (val == null || val.isEmpty) return "Mobile number is required";
    if (!RegExp(r'^\d{10}$').hasMatch(val)) {
      return "Enter a valid 10-digit phone number";
    }
    return null;
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) return "Password is required";
    if (val.length < 6) return "Password must be at least 6 characters";
    return null;
  }

  String? _validateConfirmPassword(String? val) {
    if (val == null || val.isEmpty) return "Please confirm your password";
    if (val != passController.text) return "Passwords do not match";
    return null;
  }
}