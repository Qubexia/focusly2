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

Future<void> showEditProfileSheet(BuildContext context, UserModel? user) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _EditProfileSheet(user: user),
  );
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user});

  final UserModel? user;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  final _authRepository = AuthRepository();
  final _imagePicker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  var _isSaving = false;
  var _isSendingReset = false;
  String? _selectedAvatarPath;

  UserModel? get _user => widget.user;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<bool> _ensureGalleryAccess(AppLocalizations l10n) async {
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

    if (mounted) {
      final isPermanentlyDenied =
          requestedPhotoStatus.isPermanentlyDenied ||
          requestedStorageStatus.isPermanentlyDenied;
      ScaffoldMessenger.of(context)
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

  Future<void> _pickAvatar(AppLocalizations l10n) async {
    final hasAccess = await _ensureGalleryAccess(l10n);
    if (!hasAccess) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1400,
      );
      if (pickedFile == null) return;

      setState(() {
        _selectedAvatarPath = pickedFile.path;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
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

  Future<void> _sendPasswordReset(AppLocalizations l10n) async {
    final email = _user?.email;
    if (email == null || email.isEmpty) return;

    setState(() => _isSendingReset = true);
    try {
      await _authRepository.forgotPassword(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.profilePasswordResetSent),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
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
      if (mounted) {
        setState(() => _isSendingReset = false);
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    context.read<AuthBloc>().add(
      AuthProfileUpdateRequested(
        name: _nameController.text.trim(),
        avatarPath: _selectedAvatarPath,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final avatarProvider = _selectedAvatarPath != null
        ? FileImage(File(_selectedAvatarPath!)) as ImageProvider
        : (_user?.avatarUrl != null && _user!.avatarUrl!.isNotEmpty
              ? NetworkImage(_user!.avatarUrl!)
              : null);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.profileEditProfileSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                          onPressed: () => _pickAvatar(l10n),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(l10n.profileChangePhoto),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
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
                    controller: _emailController,
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
                      onPressed: _isSendingReset ? null : () => _sendPasswordReset(l10n),
                      icon: _isSendingReset
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
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
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
  }
}
