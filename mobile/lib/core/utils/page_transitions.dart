import 'package:flutter/material.dart';

/// Smooth page transitions for navigation
class SmoothPageRoute<T> extends MaterialPageRoute<T> {
  SmoothPageRoute({required super.builder});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      ),
    );
  }
}

/// Scale fade transition for dialogs and modals
class ScaleFadeRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  ScaleFadeRoute({required this.builder});

  @override
  Color? get barrierColor => Colors.black54;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ),
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.9,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        )),
        child: child,
      ),
    );
  }
}

/// Slide up transition for bottom sheets
class SlideUpRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  SlideUpRoute({required this.builder});

  @override
  Color? get barrierColor => Colors.black54;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: child,
    );
  }
}

/// Helper extension for easy navigation with animations
extension NavigationExtension on BuildContext {
  Future<T?> pushWithAnimation<T>(Widget page) {
    return Navigator.of(this).push<T>(
      SmoothPageRoute(builder: (_) => page),
    );
  }

  Future<T?> pushDialog<T>(Widget dialog) {
    return Navigator.of(this).push<T>(
      ScaleFadeRoute(builder: (_) => dialog),
    );
  }

  Future<T?> pushBottomSheet<T>(Widget sheet) {
    return Navigator.of(this).push<T>(
      SlideUpRoute(builder: (_) => sheet),
    );
  }
}
