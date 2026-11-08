import 'package:flutter/material.dart';

import 'state_views.dart';

/// Temporary screen body used by features until their phase lands.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title, required this.icon, required this.message});

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: EmptyState(icon: icon, message: message),
      );
}
