import 'package:flutter/material.dart';

/// Floating particles were removed in favor of a flat background.
/// This widget is kept as a no-op so existing screen code still compiles.
class ParticleField extends StatelessWidget {
  final int count;
  final Color? color;

  const ParticleField({super.key, this.count = 0, this.color});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
