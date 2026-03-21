import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../core/models/app_user.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';

class GoleadoresScreen extends StatefulWidget {
  const GoleadoresScreen({super.key});

  @override
  State<GoleadoresScreen> createState() => _GoleadoresScreenState();
}

class _DynamicBackground extends StatefulWidget {
  final Widget child;

  const _DynamicBackground({required this.child});

  @override
  State<_DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<_DynamicBackground>
    with TickerProviderStateMixin {
  late AnimationController _primaryController;
  late AnimationController _secondaryController;
  Offset _tapPosition = Offset.zero;
  bool _showRipple = false;

  @override
  void initState() {
    super.initState();
    _primaryController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _secondaryController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  void _handleTap(TapDownDetails details) {
    setState(() {
      _tapPosition = details.localPosition;
      _showRipple = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showRipple = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTap,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_primaryController, _secondaryController]),
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.darkGrey,
                      AppTheme.mediumGrey.withOpacity(0.7 + 0.3 * math.sin(_primaryController.value * math.pi * 2)),
                      AppTheme.darkGrey.withOpacity(0.9),
                      AppTheme.darkBlue.withOpacity(0.5 + 0.5 * math.sin(_secondaryController.value * math.pi * 2)),
                    ],
                    transform: GradientRotation((_primaryController.value + _secondaryController.value) * 3.14159),
                  ),
                ),
                child: widget.child,
              );
            },
          ),
          if (_showRipple)
            Positioned(
              left: _tapPosition.dx,
              top: _tapPosition.dy,
              child: RippleEffect(position: _tapPosition),
            ),
        ],
      ),
    );
  }
}

class RippleEffect extends StatefulWidget {
  final Offset position;

  const RippleEffect({required this.position});

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _radiusAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _radiusAnimation = Tween<double>(begin: 0, end: 300).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.5, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: _radiusAnimation.value * 2,
          height: _radiusAnimation.value * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.goldAccent.withOpacity(_opacityAnimation.value),
              width: 2,
            ),
          ),
          transform: Matrix4.translationValues(-_radiusAnimation.value, -_radiusAnimation.value, 0),
        );
      },
    );
  }
}

class _GoleadoresScreenState extends State<GoleadoresScreen> {
  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('TABLA DE GOLEADORES')),
      body: _DynamicBackground(
        child: StreamBuilder<List<AppUser>>(
          stream: service.allUsers(),
          builder: (context, snapshot) {
            final users = (snapshot.data ?? [])
              ..sort((a, b) => b.goles.compareTo(a.goles));
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                ),
              );
            }
            if (users.isEmpty) {
              return const Center(
                child: Text(
                  'Sin datos de goleadores.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, i) {
                final u = users[i];
                final isTopThree = i < 3;
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(milliseconds: 300 + (i * 80)),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          gradient: isTopThree
                              ? LinearGradient(
                                  colors: [AppTheme.primaryBlue, AppTheme.lightBlue],
                                )
                              : null,
                          color: isTopThree ? null : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (isTopThree ? AppTheme.primaryBlue : Colors.black).withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: MouseRegion(
                          onEnter: (_) {
                            setState(() {});
                          },
                          onExit: (_) {
                            setState(() {});
                          },
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isTopThree
                                    ? const LinearGradient(
                                        colors: [AppTheme.goldAccent, AppTheme.darkGold],
                                      )
                                    : LinearGradient(
                                        colors: [AppTheme.lightGrey, AppTheme.accentGrey],
                                      ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isTopThree ? AppTheme.goldAccent : AppTheme.accentGrey).withOpacity(0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: isTopThree ? Colors.white : AppTheme.darkGrey,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              u.nombre,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isTopThree ? Colors.white : AppTheme.darkGrey,
                              ),
                            ),
                            subtitle: Text(
                              'PJ ${u.pj}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isTopThree ? Colors.white70 : AppTheme.accentGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Text(
                              '${u.goles}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: isTopThree ? AppTheme.goldAccent : AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: users.length,
            );
          },
        ),
      ),
    );
  }
}
