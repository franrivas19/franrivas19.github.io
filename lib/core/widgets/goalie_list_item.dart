import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart';

class GoalieListItem extends StatefulWidget {
  final AppUser user;
  final int position;
  final int animationDelay;

  const GoalieListItem({
    Key? key,
    required this.user,
    required this.position,
    required this.animationDelay,
  }) : super(key: key);

  @override
  State<GoalieListItem> createState() => _GoalieListItemState();
}

class _GoalieListItemState extends State<GoalieListItem> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );

    _elevationAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTopThree = widget.position < 3;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (widget.animationDelay * 80)),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: MouseRegion(
            onEnter: (_) => _hoverController.forward(),
            onExit: (_) => _hoverController.reverse(),
            child: AnimatedBuilder(
              animation: Listenable.merge([_scaleAnimation, _elevationAnimation]),
              builder: (context, _) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
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
                          color: (isTopThree ? AppTheme.primaryBlue : Colors.black)
                              .withOpacity(0.15 + (0.1 * _elevationAnimation.value / 8)),
                          blurRadius: 10 + (4 * _elevationAnimation.value / 8),
                          offset: Offset(0, 4 + (4 * _elevationAnimation.value / 8)),
                        ),
                      ],
                    ),
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
                              color: (isTopThree ? AppTheme.goldAccent : AppTheme.accentGrey)
                                  .withOpacity(0.4 + (0.2 * _elevationAnimation.value / 8)),
                              blurRadius: 8 + (4 * _elevationAnimation.value / 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${widget.position + 1}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isTopThree ? Colors.white : AppTheme.darkGrey,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        widget.user.nombre,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isTopThree ? Colors.white : AppTheme.darkGrey,
                        ),
                      ),
                      subtitle: Text(
                        'PJ ${widget.user.pj}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isTopThree ? Colors.white70 : AppTheme.accentGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: AnimatedBuilder(
                        animation: _elevationAnimation,
                        builder: (context, _) {
                          return Transform.scale(
                            scale: 1.0 + (0.1 * _elevationAnimation.value / 8),
                            child: Text(
                              '${widget.user.goles}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: isTopThree ? AppTheme.goldAccent : AppTheme.primaryBlue,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
