import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../Bloc/RegisterBloc.dart';
import '../Model/UserModel.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final shopController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();
  final numberController = TextEditingController();
  final passController = TextEditingController();
  final confirmController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register")),
      body: BlocConsumer<RegisterBloc, RegisterState>(
        listener: (context, state) {
          if (state is RegisterSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Registered successfully!")),
            );
          } else if (state is RegisterFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error)),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  _buildTextField(shopController, "Shop Name"),
                  _buildTextField(addressController, "Address"),
                  _buildTextField(emailController, "Email", inputType: TextInputType.emailAddress),
                  _buildTextField(numberController, "Mobile Number", inputType: TextInputType.phone),
                  _buildTextField(passController, "Password", obscure: true),
                  _buildTextField(confirmController, "Confirm Password", obscure: true),
                  SizedBox(height: 20),
                  ElevatedButton(
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
                          password: passController.text,
                        );
                        context.read<RegisterBloc>().add(SubmitRegisterEvent(user));
                      }
                    },
                    child: state is RegisterLoading
                        ? CircularProgressIndicator()
                        : Text("Register"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscure = false, TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) =>
        value == null || value.isEmpty ? 'Enter $label' : null,
      ),
    );
  }
}
