import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event_state.dart';

Future<void> showEditProfileSheet(BuildContext context, UserModel? user) async {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: user?.name ?? '');
  final emailController = TextEditingController(text: user?.email ?? '');
  final authRepository = AuthRepository();
  final imagePicker = ImagePicker();

  var isSaving = false;
  var isSendingReset = false;
  String? selectedAvatarPath;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final isDark = Theme.of(sheetContext).brightness == Brightness.dark;

      return StatefulBuilder(
        builder: (context, setModalState) {
          Future<bool> ensureGalleryAccess() async {
            if (!Platform.isAndroid) return true;

            final photoStatus = await Permission.photos.status;
            if (photoStatus.isGranted || photoStatus.isLimited) {
              return true;
            }

            final requestedPhotoStatus = await Permission.photos.request();
            if (requestedPhotoStatus.isGranted || requestedPhotoStatus.isLimited) {
              return true;
            }

            final storageStatus = await Permission.storage.status;
            if (storageStatus.isGranted) return true;

            final requestedStorageStatus = await Permission.storage.request();
            if (requestedStorageStatus.isGranted) return true;

            if (sheetContext.mounted) {
              final isPermanentlyDenied =
                  requestedPhotoStatus.isPermanentlyDenied ||
                  requestedStorageStatus.isPermanentlyDenied;
              ScaffoldMessenger.of(sheetContext)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      isPermanentlyDenied
                          ? 'Photo access is blocked. Please enable it from app settings.'
                          : 'Photo access is required to choose an avatar.',
                    ),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    action: isPermanentlyDenied
                        ? SnackBarAction(
                            label: 'Settings',
                            onPressed: openAppSettings,
                          )
                        : null,
                  ),
                );
            }

            return false;
          }

          Future<void> pickAvatar() async {
            final hasAccess = await ensureGalleryAccess();
            if (!hasAccess) return;

            try {
              final pickedFile = await imagePicker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 85,
                maxWidth: 1400,
              );
              if (pickedFile == null) return;

              setModalState(() {
                selectedAvatarPath = pickedFile.path;
              });
            } catch (_) {
              if (sheetContext.mounted) {
                ScaffoldMessenger.of(sheetContext)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Could not open your photo library right now.'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
              }
            }
          }

          Future<void> sendPasswordReset() async {
            final email = user?.email;
            if (email == null || email.isEmpty) return;

            setModalState(() => isSendingReset = true);
            try {
              await authRepository.forgotPassword(email: email);
              if (sheetContext.mounted) {
                ScaffoldMessenger.of(sheetContext)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Password reset link sent to your email.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
              }
            } catch (_) {
              if (sheetContext.mounted) {
                ScaffoldMessenger.of(sheetContext)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Could not send reset link right now.'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
              }
            } finally {
              if (sheetContext.mounted) {
                setModalState(() => isSendingReset = false);
              }
            }
          }

          Future<void> submit() async {
            if (!formKey.currentState!.validate()) return;

            setModalState(() => isSaving = true);
            context.read<AuthBloc>().add(
              AuthProfileUpdateRequested(
                name: nameController.text.trim(),
                avatarPath: selectedAvatarPath,
              ),
            );
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
          }

          final avatarProvider = selectedAvatarPath != null
              ? FileImage(File(selectedAvatarPath!)) as ImageProvider
              : (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                    ? NetworkImage(user.avatarUrl!)
                    : null);

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.86,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white24 : Colors.black12,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Edit Profile',
                          style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Update your profile image, name, and security access.',
                          style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                backgroundImage: avatarProvider,
                                child: avatarProvider == null
                                    ? const Icon(
                                        Icons.person_rounded,
                                        color: AppColors.primary,
                                        size: 34,
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: pickAvatar,
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Change Photo'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Display name',
                            hintText: 'Enter your full name',
                          ),
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) return 'Name is required';
                            if (trimmed.length < 2) return 'Name is too short';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            helperText: 'Email change is not available yet.',
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isSendingReset ? null : sendPasswordReset,
                            icon: isSendingReset
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.lock_reset_rounded),
                            label: const Text('Send Password Reset Link'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : submit,
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );

  nameController.dispose();
  emailController.dispose();
}
