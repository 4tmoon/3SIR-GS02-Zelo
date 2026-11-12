import 'package:flutter/material.dart';

import '../models/issue.dart';
import 'category_style.dart';

/// Pino do mapa: o ícone mostra a categoria e a cor mostra o andamento.
class IssuePin extends StatelessWidget {
  final Issue issue;
  final VoidCallback onTap;

  const IssuePin({super.key, required this.issue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: CategoryStyle.stateColor(issue),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [
            BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(CategoryStyle.icon(issue.category), size: 20, color: Colors.white),
      ),
    );
  }
}