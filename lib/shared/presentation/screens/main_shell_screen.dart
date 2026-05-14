import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routing/app_router.dart';
import '../../../features/auth/domain/notifiers/auth_notifier.dart';

/// Navigation item definition
class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

const _navItems = [
  NavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    route: AppRoutes.dashboard,
  ),
  NavItem(
    label: 'Tournaments',
    icon: Icons.emoji_events_outlined,
    activeIcon: Icons.emoji_events,
    route: AppRoutes.tournaments,
  ),
  NavItem(
    label: 'Teams',
    icon: Icons.groups_outlined,
    activeIcon: Icons.groups,
    route: AppRoutes.teams,
  ),
  NavItem(
    label: 'Players',
    icon: Icons.person_outlined,
    activeIcon: Icons.person,
    route: AppRoutes.players,
  ),
  NavItem(
    label: 'Matches',
    icon: Icons.sports_soccer_outlined,
    activeIcon: Icons.sports_soccer,
    route: AppRoutes.matches,
  ),
  NavItem(
    label: 'Standings',
    icon: Icons.format_list_numbered_outlined,
    activeIcon: Icons.format_list_numbered,
    route: AppRoutes.standings,
  ),
  NavItem(
    label: 'Awards',
    icon: Icons.workspace_premium_outlined,
    activeIcon: Icons.workspace_premium,
    route: AppRoutes.awards,
  ),
];

/// Provider for current navigation index
final _navIndexProvider = StateProvider<int>((ref) => 0);

/// Responsive shell with sidebar (web/tablet) or bottom nav (mobile)
class MainShellScreen extends ConsumerWidget {
  final Widget child;

  const MainShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 900;
    final navIndex = ref.watch(_navIndexProvider);

    if (isWide) {
      return _WideLayout(child: child, navIndex: navIndex, ref: ref);
    }
    return _MobileLayout(child: child, navIndex: navIndex, ref: ref);
  }
}

// ---- Wide (Web/Tablet) Layout ----
class _WideLayout extends StatelessWidget {
  final Widget child;
  final int navIndex;
  final WidgetRef ref;

  const _WideLayout({
    required this.child,
    required this.navIndex,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _Sidebar(navIndex: navIndex, ref: ref),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Sidebar extends StatefulWidget {
  final int navIndex;
  final WidgetRef ref;

  const _Sidebar({required this.navIndex, required this.ref});

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final width = _collapsed
        ? AppDimensions.sidebarCollapsedWidth
        : AppDimensions.sidebarWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              itemCount: _navItems.length,
              itemBuilder: (context, i) => _buildNavItem(i),
            ),
          ),

          const Divider(height: 1),
          // Bottom actions
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.sports_soccer, size: 22, color: Colors.black),
          ),
          if (!_collapsed) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FOOTBALL',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'MANAGER',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 10,
                      color: AppColors.primary,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
          IconButton(
            onPressed: () => setState(() => _collapsed = !_collapsed),
            icon: Icon(
              _collapsed ? Icons.menu_open : Icons.menu,
              size: 20,
              color: AppColors.textTertiary,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isActive = widget.navIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: InkWell(
          onTap: () {
            widget.ref.read(_navIndexProvider.notifier).state = index;
            context.go(item.route);
          },
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: isActive
                  ? Border.all(color: AppColors.primary.withOpacity(0.2))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: 20,
                  color: isActive ? AppColors.primary : AppColors.textTertiary,
                ),
                if (!_collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: _collapsed
          ? IconButton(
              onPressed: _handleSignOut,
              icon: const Icon(Icons.logout, color: AppColors.error, size: 20),
              tooltip: 'Sign Out',
            )
          : OutlinedButton.icon(
              onPressed: _handleSignOut,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
            ),
    );
  }

  void _handleSignOut() {
    widget.ref.read(authNotifierProvider.notifier).signOut();
  }
}

// ---- Mobile Layout ----
class _MobileLayout extends StatelessWidget {
  final Widget child;
  final int navIndex;
  final WidgetRef ref;

  const _MobileLayout({
    required this.child,
    required this.navIndex,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    // Show only first 5 items in bottom nav
    final items = _navItems.take(5).toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: AppDimensions.navBarHeight,
          child: Row(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isActive = navIndex == i;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref.read(_navIndexProvider.notifier).state = i;
                    context.go(item.route);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isActive ? item.activeIcon : item.icon,
                            key: ValueKey(isActive),
                            size: 24,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
