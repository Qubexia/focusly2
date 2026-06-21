import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zakerly/l10n/app_localizations.dart';

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
      final l10n = AppLocalizations.of(sheetContext);

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
                          ? l10n.profilePhotoAccessBlocked
                          : l10n.profilePhotoAccessRequired,
                    ),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    action: isPermanentlyDenied
                        ? SnackBarAction(
                            label: l10n.profileSettings,
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
                    SnackBar(
                      content: Text(l10n.profilePhotoLibraryError),
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
                    SnackBar(
                      content: Text(l10n.profilePasswordResetSent),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
              }
            } catch (_) {
              if (sheetContext.mounted) {
                ScaffoldMessenger.of(sheetContext)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(l10n.profilePasswordResetError),
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
                          l10n.profileEditProfile,
                          style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.profileEditProfileSubtitle,
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
                                label: Text(l10n.profileChangePhoto),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: nameController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.profileDisplayName,
                            hintText: l10n.profileDisplayNameHint,
                          ),
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) return l10n.profileNameRequired;
                            if (trimmed.length < 2) return l10n.profileNameTooShort;
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: l10n.profileEmail,
                            helperText: l10n.profileEmailChangeUnavailable,
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
                            label: Text(l10n.profileSendPasswordReset),
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
                                : Text(l10n.profileSaveChanges),
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
