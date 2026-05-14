import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_router.dart';
import '../../domain/notifiers/auth_notifier.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/glass_container.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await ref.read(authNotifierProvider.notifier).signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );

    // Nếu login thành công, navigate thủ công để chắc chắn
    if (success && mounted) {
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    // Hiển thị lỗi qua snackbar
    ref.listen(authNotifierProvider, (prev, next) {
      if (next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0A0E1A),
                    Color(0xFF0D1B2A),
                    Color(0xFF0A0E1A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Glow top-right
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Glow bottom-left
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 480 : double.infinity,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo & Header
                      _buildHeader()
                          .animate()
                          .fade(duration: 600.ms)
                          .slideY(begin: -0.2),

                      const SizedBox(height: 48),

                      // Login Card
                      GlassContainer(
                        padding: const EdgeInsets.all(AppDimensions.paddingXL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Admin Sign In',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontFamily: 'Rajdhani',
                                    fontWeight: FontWeight.w700,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Access your tournament dashboard',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // Email
                            AppTextField(
                              controller: _emailController,
                              label: 'Email',
                              hint: 'admin@example.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Email is required';
                                }
                                if (!v.contains('@')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password
                            AppTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: '••••••••',
                              prefixIcon: Icons.lock_outlined,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              suffixIcon: _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              onSuffixTap: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Password is required';
                                }
                                if (v.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                              onSubmit: (_) => _handleLogin(),
                            ),
                            const SizedBox(height: 32),

                            // Login button
                            AppButton(
                              label: 'Sign In',
                              onPressed: _handleLogin,
                              isLoading: authState.isLoading,
                              icon: Icons.login,
                            ),
                          ],
                        ),
                      )
                          .animate(delay: 200.ms)
                          .fade(duration: 600.ms)
                          .slideY(begin: 0.3, curve: Curves.easeOut),

                      const SizedBox(height: 24),

                      Text(
                        'Authorized personnel only',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ).animate(delay: 400.ms).fade(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.sports_soccer,
            size: 50,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'FOOTBALL',
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: 6,
          ),
        ),
        const Text(
          'TOURNAMENT MANAGER',
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}
