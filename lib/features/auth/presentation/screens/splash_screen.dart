import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_router.dart';
import '../../domain/providers/auth_providers.dart';

/// Splash screen — hiển thị animation trong khi chờ Firebase
/// khởi tạo và restore auth session.
/// Navigation được xử lý bởi GoRouter redirect + timeout fallback.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Timeout fallback: nếu sau 4 giây vẫn chưa navigate
    // (auth stream chưa emit) → force về login
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        context.go(AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe auth state — khi có giá trị thì navigate
    ref.listen(authStateProvider, (previous, next) {
      // Chỉ xử lý khi đã có data (không còn loading)
      if (next.isLoading) return;
      if (_hasNavigated) return;

      next.whenData((user) {
        if (!mounted) return;
        _hasNavigated = true;
        if (user != null) {
          context.go(AppRoutes.dashboard);
        } else {
          context.go(AppRoutes.login);
        }
      });

      // Nếu có lỗi → về login
      if (next.hasError && mounted) {
        _hasNavigated = true;
        context.go(AppRoutes.login);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sports_soccer,
                  size: 68,
                  color: Colors.black,
                ),
              )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .fade(),

              const SizedBox(height: 32),

              const Text(
                'FOOTBALL',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: 8,
                ),
              )
                  .animate(delay: 300.ms)
                  .slideY(begin: 0.3, curve: Curves.easeOut)
                  .fade(),

              const Text(
                'TOURNAMENT MANAGER',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                  letterSpacing: 4,
                ),
              )
                  .animate(delay: 500.ms)
                  .slideY(begin: 0.3, curve: Curves.easeOut)
                  .fade(),

              const SizedBox(height: 80),

              SizedBox(
                width: 48,
                height: 4,
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ).animate(delay: 700.ms).fade().scale(begin: const Offset(0, 1)),
            ],
          ),
        ),
      ),
    );
  }
}
