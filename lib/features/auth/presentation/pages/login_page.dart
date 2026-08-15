import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/routes/route_paths.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_auth_field.dart';
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
      // Never leak the raw Failure.toString() (e.g.
      // "UnexpectedFailure[cloud_firestore/permission-denied…]") to
      // the user — surface a generic retry hint instead.
      setState(() => _generalError = 'Could not sign in. Please try again.');
    }
  }

  /// Opens the Forgot Password dialog. The dialog has its own username
  /// field, submit/cancel buttons, and inline feedback. We surface
  /// a generic success snackbar on the "reset issued" path and an
  /// inline error on validation / lookup failure.
  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    if (mounted) {
      FocusScope.of(context).unfocus();
    }
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<_ForgotPasswordOutcome>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ForgotPasswordDialog(l10n: l10n),
    );
    if (!mounted || result == null) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.authForgotPasswordSuccessWithSpamHint),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
      ),
    );
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
                      title: l10n.authLoginTitle.toUpperCase(),
                      subtitle: l10n.authLoginSubtitle,
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
                            errorText: _usernameError,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _passwordFocus.requestFocus(),
                            autofillHints: const [AutofillHints.username],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppAuthField(
                            controller: _passwordCtl,
                            focusNode: _passwordFocus,
                            icon: Icons.lock_outline_rounded,
                            label: l10n.authPassword,
                            errorText: _passwordError,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            autofillHints: const [AutofillHints.password],
                            trailing: AppObscureToggle(
                              isObscured: _obscurePassword,
                              onTap: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
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
                                : Text(l10n.authLoginButton.toUpperCase()),
                          ),
                          // "Forgot Password?" — sits directly below the
                          // primary CTA so it reads as a secondary action on
                          // the sign-in form. Opens a dialog that asks for
                          // the sign-in username, looks it up via the public
                          // `usernames` collection, and dispatches the
                          // Firebase password-reset flow.
                          Align(
                            alignment: Alignment.center,
                            child: TextButton(
                              onPressed: _submitting
                                  ? null
                                  : () => _showForgotPasswordDialog(context),
                              child: Text(l10n.authForgotPassword),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton.icon(
                      onPressed: _submitting
                          ? null
                          : () => context.go(RoutePaths.signup),
                      icon: const Icon(Icons.bolt_rounded, size: 18),
                      label: Text(l10n.authNoAccount),
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

/// Branded auth-page header — kicker, title and subtitle.
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

/// Tagged outcome returned by [_ForgotPasswordDialog] so the host
/// page can show a snackbar without depending on dialog internals.
/// Only the success branch is surfaced as a snackbar — failures are
/// shown inline in the dialog itself.
class _ForgotPasswordOutcome {
  const _ForgotPasswordOutcome({required this.isSuccess});

  final bool isSuccess;
}

/// Dialog asking for the sign-in username and dispatching the
/// Firebase password-reset flow. Looks up the username via the
/// publicly-readable `usernames/{username}` collection so the
/// reset works while the user is signed out. Lives in this file
/// rather than its own widget file because it's tightly coupled
/// to the login page and only used here.
class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _emailCtl = TextEditingController();
  final _emailFocus = FocusNode();

  String? _emailError;
  bool _submitting = false;

  late final AuthService _auth = getIt<AuthService>();

  @override
  void dispose() {
    _emailCtl.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  bool _validateLocal() {
    final email = _emailCtl.text.trim();
    final ok = email.isNotEmpty &&
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    setState(() {
      _emailError = ok ? null : widget.l10n.authForgotPasswordInvalidUsername;
    });
    return ok;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_validateLocal()) return;

    if (mounted) {
      FocusScope.of(context).unfocus();
    }

    setState(() {
      _submitting = true;
      _emailError = null;
    });

    final result = await _auth.resetPassword(
      email: _emailCtl.text.trim(),
    );

    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.of(context).pop(
        const _ForgotPasswordOutcome(isSuccess: true),
      );
      return;
    }

    final failure = result.failure;
    final isInvalid = failure is AuthFailure &&
        failure.code == AuthFailureCode.invalidCredentials;
    final message = isInvalid
        ? widget.l10n.authForgotPasswordInvalidUsername
        : widget.l10n.authForgotPasswordGenericError;

    setState(() {
      _submitting = false;
      _emailError = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = widget.l10n;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.lock_reset_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.authForgotPasswordTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.authForgotPasswordBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _emailCtl,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            autofocus: true,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: l10n.authEmail,
              prefixIcon: const Icon(Icons.alternate_email_rounded),
              errorText: _emailError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.authForgotPasswordCancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.authForgotPasswordSend),
        ),
      ],
    );
  }
}
