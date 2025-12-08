import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BackButtonRoute extends StatelessWidget {
  final String route;
  const BackButtonRoute({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 26),
            onPressed: () {
              context.go(route);
            },
          ),
        ),
      ),
    );
  }
}
