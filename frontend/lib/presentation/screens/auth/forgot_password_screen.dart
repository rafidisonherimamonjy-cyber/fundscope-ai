import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/common_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ApiClient().post("/auth/forgot-password", data: {"email": _emailController.text.trim()});
      setState(() => _submitted = true);
    } catch (_) {
      // Par design, l'API répond toujours 202 : on affiche le même message de confirmation.
      setState(() => _submitted = true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mot de passe oublié")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _submitted
              ? EmptyState(
                  icon: Icons.mark_email_read_outlined,
                  title: "Email envoyé",
                  message: "Si un compte existe avec cette adresse, des instructions de réinitialisation "
                      "viennent de vous être envoyées.",
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Indiquez l'adresse email associée à votre compte, nous vous enverrons "
                        "les instructions de réinitialisation.",
                      ),
                      const SizedBox(height: 24),
                      AppTextField(
                        label: "Email",
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(label: "Envoyer", onPressed: _submit, isLoading: _isSubmitting),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
