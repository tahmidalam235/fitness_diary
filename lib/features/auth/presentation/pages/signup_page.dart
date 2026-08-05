import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/routes/route_paths.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
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
      body: SafeArea(
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
                  const _BrandMark(),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.authSignupTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.authSignupSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _AuthField(
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
                  _AuthField(
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
                    trailing: _ObscureToggle(
                      isObscured: _obscurePassword,
                      onTap: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _AuthField(
                    controller: _confirmCtl,
                    focusNode: _confirmFocus,
                    icon: Icons.lock_outline_rounded,
                    label: l10n.authConfirmPassword,
                    errorText: _confirmError,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _nameFocus.requestFocus(),
                    trailing: _ObscureToggle(
                      isObscured: _obscureConfirm,
                      onTap: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _AuthField(
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
                  _AuthField(
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
                    _BannerError(text: _generalError!),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.authSignupButton),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => context.go(RoutePaths.login),
                    child: Text(l10n.authHasAccount),
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

/// A single rounded row containing a gradient icon, a label, and an
/// optional trailing widget (used for the password-eye toggle).
/// Mirrors the `_InlineField` look from the profile page so the
/// app feels consistent.
class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.focusNode,
    required this.icon,
    required this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.trailing,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final IconData icon;
  final String label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = errorText != null;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: hasError
              ? theme.colorScheme.error.withValues(alpha: 0.7)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  onSubmitted: onSubmitted,
                  autofillHints: autofillHints,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    labelText: label,
                    labelStyle: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    hintText: hint,
                    hintStyle: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          if (hasError) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(
                errorText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ObscureToggle extends StatelessWidget {
  const _ObscureToggle({required this.isObscured, required this.onTap});

  final bool isObscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        isObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        size: 20,
      ),
      tooltip: isObscured ? 'Show password' : 'Hide password',
      visualDensity: VisualDensity.compact,
    );
  }
}

class _BannerError extends StatelessWidget {
  const _BannerError({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.error,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small brand mark above the form — same gradient squircle as the
/// splash, scaled down so it doesn't dominate the screen.
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFF0F1226),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Image.asset(
          'assets/logo/fitness_diary_compact.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
