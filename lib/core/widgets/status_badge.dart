import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../../shared/models/enums.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      ReportStatus.reported => (AppColors.reported, const Color(0xFF880E4F)),
      ReportStatus.inProgress => (AppColors.inProgress, const Color(0xFF795548)),
      ReportStatus.resolved => (AppColors.resolved, AppColors.primaryGreen),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.labelFr,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
