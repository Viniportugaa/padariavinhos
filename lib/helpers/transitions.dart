import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

CustomTransitionPage<T> _customTransitionPage<T>({
  required Widget child,
  required GoRouterState state,
  required Widget Function(
      BuildContext,
      Animation<double>,
      Animation<double>,
      Widget,
      )
  transitionBuilder,
  Duration duration = const Duration(milliseconds: 400),
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    child: child,
    transitionsBuilder: transitionBuilder,
  );
}

/// 🟣 Fade suave (usado em telas simples e de transição leve)
CustomTransitionPage<T> fadeTransitionPage<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return _customTransitionPage(
    child: child,
    state: state,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutExpo);
      return FadeTransition(opacity: curved, child: child);
    },
  );
}

/// 🔵 Slide horizontal (estilo iOS, ideal para navegação lateral)
CustomTransitionPage<T> slideTransitionPage<T>({
  required Widget child,
  required GoRouterState state,
  Offset beginOffset = const Offset(1, 0),
}) {
  return _customTransitionPage(
    child: child,
    state: state,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(begin: beginOffset, end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutExpo));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

/// 🟢 Slide + Fade (principal — usado em delivery apps para trocar páginas)
CustomTransitionPage<T> slideFadeTransitionPage<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return _customTransitionPage(
    child: child,
    state: state,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final slide = Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(curved);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

/// 🟠 Zoom + Fade (ótimo para splash, login, e detalhes de produto)
CustomTransitionPage<T> scaleTransitionPage<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return _customTransitionPage(
    child: child,
    state: state,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutExpo);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: curved, child: child),
      );
    },
  );
}

/// 🔴 Rotação leve + Fade (opcional, para páginas criativas ou modais)
CustomTransitionPage<T> rotateTransitionPage<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return _customTransitionPage(
    child: child,
    state: state,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOutBack);
      return RotationTransition(
        turns: Tween(begin: 0.97, end: 1.0).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}
