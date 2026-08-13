import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reference_provider.dart';
import '../../widgets/common_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _organizationController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  int? _countryId;
  int? _sectorId;
  String _orgType = "startup";
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  static const _orgTypes = {
    "startup": "Startup",
    "pme": "PME",
    "ong": "ONG",
    "association": "Association",
    "cooperative": "Coopérative",
    "structure_appui": "Structure d'appui",
    "consultant": "Consultant(e)",
    "autre": "Autre",
  };

  @override
  void dispose() {
    _fullNameController.dispose();
    _organizationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_countryId == null) {
      setState(() => _errorMessage = "Veuillez sélectionner votre pays");
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authProvider.notifier).register(
            fullName: _fullNameController.text.trim(),
            organizationName: _organizationController.text.trim(),
            orgType: _orgType,
            countryId: _countryId!,
            sectorId: _sectorId,
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            password: _passwordController.text,
          );
      final state = ref.read(authProvider);
      if (state.hasError) {
        setState(() => _errorMessage = state.error.toString());
      }
      // Redirection automatique vers l'Onboarding gérée par le routeur.
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countriesAsync = ref.watch(countriesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Créer un compte")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: "Nom complet",
                  controller: _fullNameController,
                  validator: (v) => Validators.required(v, label: "Le nom"),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: "Organisation",
                  controller: _organizationController,
                  hint: "Nom de votre startup, ONG, PME...",
                  validator: (v) => Validators.required(v, label: "L'organisation"),
                ),
                const SizedBox(height: 16),
                Text("Type de structure", style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _orgType,
                  items: _orgTypes.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (value) => setState(() => _orgType = value!),
                ),
                const SizedBox(height: 16),
                Text("Pays", style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                countriesAsync.when(
                  data: (countries) => DropdownButtonFormField<int>(
                    value: _countryId,
                    hint: const Text("Sélectionner votre pays"),
                    items: countries.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (value) => setState(() => _countryId = value),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text("Impossible de charger les pays", style: TextStyle(color: theme.colorScheme.error)),
                ),
                const SizedBox(height: 16),
                Text("Secteur d'activité (optionnel)", style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                categoriesAsync.when(
                  data: (categories) => DropdownButtonFormField<int>(
                    value: _sectorId,
                    hint: const Text("Sélectionner un secteur"),
                    items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (value) => setState(() => _sectorId = value),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text("Impossible de charger les secteurs", style: TextStyle(color: theme.colorScheme.error)),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: "Email",
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: "Téléphone (optionnel)",
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: "Mot de passe",
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: Validators.password,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
                ],
                const SizedBox(height: 24),
                PrimaryButton(label: "Créer mon compte", onPressed: _submit, isLoading: _isSubmitting),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
