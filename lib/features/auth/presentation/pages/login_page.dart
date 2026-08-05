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

/// Returning-user login page.
///
/// Username + password with a primary CTA. On success, the router's
/// redirect (which watches [AuthService]) sends the user to
/// `/dashboard`. On failure, shows an inline banner.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  String? _usernameError;
  String? _passwordError;
  String? _generalError;
  bool _obscurePassword = true;
  bool _submitting = false;

  late final AuthService _auth = getIt<AuthService>();

  @override
  void dispose() {
    _usernameCtl.dispose();
    _passwordCtl.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool _validateLocal() {
    final ok =
        _usernameCtl.text.trim().isNotEmpty && _passwordCtl.text.isNotEmpty;
    setState(() {
      _usernameError = _usernameCtl.text.trim().isEmpty ? 'Required' : null;
      _passwordError = _passwordCtl.text.isEmpty ? 'Required' : null;
      _generalError = null;
    });
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

    final result = await _auth.login(
      username: _usernameCtl.text.trim(),
      password: _passwordCtl.text,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.isSuccess) return; // router redirect handles navigation

    final l10n = AppLocalizations.of(context);
    final failure = result.failure;
    if (failure is AuthFailure &&
        failure.code == AuthFailureCode.invalidCredentials) {
      setState(() => _generalError = l10n.authInvalidCredentials);
    } else {
      setState(() => _generalError = failure?.toString() ?? 'Try again.');
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
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1226),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.35,
                            ),
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
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.authLoginTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.authLoginSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _LoginField(
                    controller: _usernameCtl,
                    focusNode: _usernameFocus,
                    icon: Icons.person_outline_rounded,
                    label: l10n.authUsername,
                    errorText: _usernameError,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                    autofillHints: const [AutofillHints.username],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _LoginField(
                    controller: _passwordCtl,
                    focusNode: _passwordFocus,
                    icon: Icons.lock_outline_rounded,
                    label: l10n.authPassword,
                    errorText: _passwordError,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    autofillHints: const [AutofillHints.password],
                    trailing: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 20,
                      ),
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      visualDensity: VisualDensity.compact,
                    ),
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
                        : Text(l10n.authLoginButton),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => context.go(RoutePaths.signup),
                    child: Text(l10n.authNoAccount),
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

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.focusNode,
    required this.icon,
    required this.label,
    this.errorText,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.trailing,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final IconData icon;
  final String label;
  final String? errorText;
  final bool obscureText;
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
