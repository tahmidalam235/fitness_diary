import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/routes/route_paths.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_auth_field.dart';
import '../../data/auth_service.dart';

/// First-launch account creation page.
///
/// Five fields (username, password, confirm, display name, email)
/// with a single primary CTA. Validation happens in the repository
/// so the same rules apply to any future caller (CLI, deep link,
/// tests). On success, the router's redirect sends the user to
/// `/dashboard`.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _usernameCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();

  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();

  String? _usernameError;
  String? _passwordError;
  String? _confirmError;
  String? _nameError;
  String? _emailError;
  String? _generalError;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  late final AuthService _auth = getIt<AuthService>();

  @override
  void dispose() {
    _usernameCtl.dispose();
    _passwordCtl.dispose();
    _confirmCtl.dispose();
    _nameCtl.dispose();
    _emailCtl.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  /// Field-level validation. Runs before submit so we can show
  /// inline errors without a round trip to the repository. The
  /// repository re-validates as the source of truth.
  bool _validateLocal() {
    setState(() {
      _usernameError = null;
      _passwordError = null;
      _confirmError = null;
      _nameError = null;
      _emailError = null;
      _generalError = null;
    });

    final username = _usernameCtl.text.trim();
    final password = _passwordCtl.text;
    final confirm = _confirmCtl.text;
    final name = _nameCtl.text.trim();
    final email = _emailCtl.text.trim();

    var ok = true;
    if (username.isEmpty) {
      _usernameError = 'Required';
      ok = false;
    } else if (username.length < 3 || username.length > 32) {
      _usernameError = '3–32 characters';
      ok = false;
    } else if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(username)) {
      _usernameError = 'Letters, numbers, and underscores only';
      ok = false;
    }
    if (password.length < 6) {
      _passwordError = 'At least 6 characters';
      ok = false;
    }
    if (confirm != password) {
      _confirmError = 'Passwords do not match';
      ok = false;
    }
    if (name.isEmpty) {
      _nameError = 'Required';
      ok = false;
    }
    if (email.isEmpty) {
      _emailError = 'Required';
      ok = false;
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _emailError = 'Enter a valid email';
      ok = false;
    }
    if (!ok) setState(() {});
    return ok;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_validateLocal()) return;

    // Unfocus all fields before navigating/submitting to avoid
    // "FocusScopeNode used after being disposed" errors.
    if (mounted) {
      FocusScope.of(context).unfocus();
    }

    setState(() {
      _submitting = true;
      _generalError = null;
    });

    final result = await _auth.signup(
      username: _usernameCtl.text.trim(),
      password: _passwordCtl.text,
      confirmPassword: _confirmCtl.text,
      displayName: _nameCtl.text.trim(),
      email: _emailCtl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.isSuccess) {
      // Router redirect watches AuthService and sends us to
      // /dashboard automatically.
      return;
    }

    final failure = result.failure;
    if (failure is ValidationFailure) {
      setState(() {
        _usernameError = failure.errors['username'];
        _passwordError = failure.errors['password'];
        _confirmError = failure.errors['confirmPassword'];
        _nameError = failure.errors['displayName'];
        _emailError = failure.errors['email'];
      });
    } else if (failure is AuthFailure) {
      final l10n = AppLocalizations.of(context);
      switch (failure.code) {
        case AuthFailureCode.usernameTaken:
          setState(() => _usernameError = l10n.authUsernameTaken);
        case AuthFailureCode.invalidCredentials:
        case AuthFailureCode.userNotFound:
        case AuthFailureCode.unknown:
          setState(() => _generalError = failure.message);
      }
    } else {
      setState(() => _generalError = 'Something went wrong. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: AppAuthBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppAuthBrandMark(),
                    const SizedBox(height: AppSpacing.lg),
                    _AuthHeader(
                      title: l10n.authSignupTitle.toUpperCase(),
                      subtitle: l10n.authSignupSubtitle,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 28,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppAuthField(
                            controller: _usernameCtl,
                            focusNode: _usernameFocus,
                            icon: Icons.person_outline_rounded,
                            label: l10n.authUsername,
                            hint: l10n.authUsernameRule,
                            errorText: _usernameError,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _passwordFocus.requestFocus(),
                            autofillHints: const [AutofillHints.newUsername],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppAuthField(
                            controller: _passwordCtl,
                            focusNode: _passwordFocus,
                            icon: Icons.lock_outline_rounded,
                            label: l10n.authPassword,
                            hint: l10n.authPasswordRule,
                            errorText: _passwordError,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _confirmFocus.requestFocus(),
                            autofillHints: const [AutofillHints.newPassword],
                            trailing: AppObscureToggle(
                              isObscured: _obscurePassword,
                              onTap: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppAuthField(
                            controller: _confirmCtl,
                            focusNode: _confirmFocus,
                            icon: Icons.lock_outline_rounded,
                            label: l10n.authConfirmPassword,
                            errorText: _confirmError,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _nameFocus.requestFocus(),
                            trailing: AppObscureToggle(
                              isObscured: _obscureConfirm,
                              onTap: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppAuthField(
                            controller: _nameCtl,
                            focusNode: _nameFocus,
                            icon: Icons.badge_outlined,
                            label: l10n.authDisplayName,
                            errorText: _nameError,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _emailFocus.requestFocus(),
                            autofillHints: const [AutofillHints.name],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppAuthField(
                            controller: _emailCtl,
                            focusNode: _emailFocus,
                            icon: Icons.alternate_email_rounded,
                            label: l10n.authEmail,
                            errorText: _emailError,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            autofillHints: const [AutofillHints.email],
                          ),
                          if (_generalError != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            AppAuthBannerError(text: _generalError!),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton(
                            onPressed: _submitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                              textStyle: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l10n.authSignupButton.toUpperCase()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton.icon(
                      onPressed: _submitting
                          ? null
                          : () => context.go(RoutePaths.login),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text(l10n.authHasAccount),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Branded auth-page header — title and subtitle rendered in white
/// over the gradient background.
class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.92),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
