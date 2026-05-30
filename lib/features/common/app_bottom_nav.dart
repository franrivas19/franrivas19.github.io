import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key, required this.selectedIndex});

  final int selectedIndex;

  void _go(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/resumen');
        return;
      case 1:
        context.go('/plantilla');
        return;
      case 2:
        context.go('/timer');
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: const BoxDecoration(color: Color(0xFFE8E2EE)),
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                selected: selectedIndex == 0,
                icon: Icons.person,
                label: 'Mi Perfil',
                onTap: () => _go(context, 0),
              ),
            ),
            Expanded(
              child: _NavItem(
                selected: selectedIndex == 1,
                icon: Icons.groups,
                label: 'Plantilla',
                onTap: () => _go(context, 1),
              ),
            ),
            Expanded(
              child: _NavItem(
                selected: selectedIndex == 2,
                icon: Icons.star,
                label: 'Turnos',
                onTap: () => _go(context, 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? const Color(0xFF1D1830) : const Color(0xFF4B465E);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE2D6F4) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: foreground),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
