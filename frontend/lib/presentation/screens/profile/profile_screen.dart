import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reference_provider.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/common_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Profil")),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : "?",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName, style: theme.textTheme.titleLarge),
                        Text(user.email, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        if (user.organization != null)
                          Text(user.organization!.name, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              _ProfileSectionTitle(title: "Informations"),
              _ProfileTile(
                icon: Icons.edit_outlined,
                title: "Modifier mes informations",
                onTap: () => _showEditInfoDialog(context, ref),
              ),
              _ProfileTile(
                icon: Icons.tune,
                title: "Modifier mes préférences de recherche",
                subtitle: "Secteurs, pays, montant, type de financement",
                onTap: () => context.push("/onboarding"),
              ),

              const SizedBox(height: 20),
              _ProfileSectionTitle(title: "Apparence"),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text("Mode sombre"),
                value: themeMode == ThemeMode.dark,
                onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
              ),

              const SizedBox(height: 20),
              _ProfileSectionTitle(title: "Compte"),
              _ProfileTile(
                icon: Icons.logout,
                title: "Déconnexion",
                isDestructive: true,
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Déconnexion"),
                      content: const Text("Voulez-vous vraiment vous déconnecter ?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Déconnexion")),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(authProvider.notifier).logout();
                  }
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: Text("FundScope AI · v0.1.0 (MVP)", style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
              ),
            ],
          );
        },
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: "$e"),
      ),
    );
  }

  void _showEditInfoDialog(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return;
    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone ?? "");
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mes informations"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: "Nom complet",
                controller: nameController,
                validator: (v) => Validators.required(v, label: "Le nom"),
              ),
              const SizedBox(height: 12),
              AppTextField(label: "Téléphone", controller: phoneController, keyboardType: TextInputType.phone),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await ref.read(userRepositoryProvider).updateMe(
                    fullName: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                  );
              await ref.read(authProvider.notifier).refreshUser();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionTitle extends StatelessWidget {
  final String title;
  const _ProfileSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
