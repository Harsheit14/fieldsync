import 'package:flutter/material.dart';

class LoadingSurveysWidget extends StatelessWidget {
  const LoadingSurveysWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
