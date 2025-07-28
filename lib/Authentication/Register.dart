import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../Bloc/RegisterBloc.dart';
import '../Database/UserRepository.dart';
import '../Model/UserModel.dart';
import 'Login.dart';

class Register extends StatefulWidget {
  late final UserRepository repository;
  Register({required this.repository});
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

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Container(
          width: isLargeScreen ? 600 : double.infinity,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: BlocConsumer<RegisterBloc, RegisterState>(
            listener: (context, state) {
              if (state is RegisterSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("🎉 Registered successfully!")),
                );
                shopController.clear();
                addressController.clear();
                emailController.clear();
                numberController.clear();
                passController.clear();
                confirmController.clear();
                Navigator.pushNamed(context, '/login');

              } else if (state is RegisterFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.error)),
                );
              }
            },
            builder: (context, state) {
              return Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Column(
                      children: [
                        Text(
                          "Invoxel",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Create an Account",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _buildTextField(shopController, "Shop Name", Icons.store),
                    _buildTextField(addressController, "Address", Icons.location_on),
                    _buildTextField(emailController, "Email", Icons.email,
                      inputType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Enter email';
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$');
                        if (!emailRegex.hasMatch(value))
                          return 'Enter valid email';
                        return null;
                      },
                    ),
                    _buildTextField(numberController, "Mobile Number", Icons.phone,
                      inputType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Enter Mobile Number';
                        if (!RegExp(r'^\d{10}$').hasMatch(value))
                          return 'Mobile number must be exactly 10 digits';
                        return null;
                      },
                    ),
                    _buildTextField(passController, "Password", Icons.lock, obscure: true,
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Enter Password' : null,
                    ),
                    _buildTextField(confirmController, "Confirm Password", Icons.lock_outline, obscure: true,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Enter Confirm Password';
                        if (value != passController.text)
                          return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: state is RegisterLoading
                          ? null
                          : () {
                        if (_formKey.currentState!.validate()) {
                          if (passController.text != confirmController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Passwords do not match")),
                            );
                            return;
                          }

                          final user = UserModel(
                            shopName: shopController.text,
                            address: addressController.text,
                            email: emailController.text,
                            number: numberController.text,
                            password: passController.text, role: '',
                          );
                          context.read<RegisterBloc>().add(SubmitRegisterEvent(user));
                        }
                      },
                      child: state is RegisterLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text("Register", style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Already have an account?"),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          child: Text("Login"),
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
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool obscure = false,
        TextInputType inputType = TextInputType.text,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: inputType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: validator ??
                (value) =>
            value == null || value.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }
}
