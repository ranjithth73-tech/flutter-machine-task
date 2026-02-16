import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_task_manager/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_task_manager/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:smart_task_manager/features/profile/domain/entities/user_profile.dart';
import 'package:smart_task_manager/features/profile/presentation/providers/profile_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateProfile(UserProfile currentProfile) {
    if (_formKey.currentState!.validate()) {
      final updatedProfile = currentProfile.copyWith(
        name: _nameController.text,
      );
      ref.read(profileUpdateProvider.notifier).updateProfile(updatedProfile);
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileStreamProvider);
    final isDarkMode = ref.watch(themeProvider);
    final isUpdating = ref.watch(profileUpdateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              // Navigation handled by auth wrapper
            },
          ),
        ],
      ),
      body: userProfileAsync.when(
        data: (profile) {
          if (!_isEditing && _nameController.text.isEmpty) {
            _nameController.text = profile.name;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                   const CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 50),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.email,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 32),
                  _isEditing
                      ? CustomTextField(
                          controller: _nameController,
                          label: 'Name',
                          hint: 'Enter your name',
                          validator: (value) =>
                              value!.isEmpty ? 'Name cannot be empty' : null,
                        )
                      : ListTile(
                          title: const Text('Name'),
                          subtitle: Text(profile.name),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              setState(() {
                                _isEditing = true;
                                _nameController.text = profile.name;
                              });
                            },
                          ),
                        ),
                  if (_isEditing) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                              _nameController.text = profile.name;
                            });
                          },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isUpdating ? null : () => _updateProfile(profile),
                          child: isUpdating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 32),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    value: isDarkMode,
                    onChanged: (value) {
                      ref.read(themeProvider.notifier).toggleTheme();
                    },
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
