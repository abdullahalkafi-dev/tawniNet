import 'package:awnneaapp/app/core/utils/job_display.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared vertical job-status timeline driven by real [JobTimelineStep]s.
class JobStatusTimeline extends StatelessWidget {
  const JobStatusTimeline({super.key, required this.steps, this.title});

  final List<JobTimelineStep> steps;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title ?? 'label_job_status'.tr,
            style: AppStyles.h2Of(context).copyWith(fontSize: 16),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < steps.length; i++)
            _StepRow(step: steps[i], isLast: i == steps.length - 1),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.isLast});

  final JobTimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final doneColor = AppColors.primary;
    final idleColor =
        context.isDarkMode ? AppColors.darkBorder : const Color(0xFFE5E7EB);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: step.done ? doneColor : idleColor,
                shape: BoxShape.circle,
                border: step.active && !step.done
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
              ),
              child: step.done
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : step.active
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
            ),
            if (!isLast)
              Container(width: 2, height: 28, color: idleColor),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: AppStyles.bodyLargeOf(context).copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: step.done
                        ? context.textPrimaryColor
                        : context.textHintColor,
                  ),
                ),
                Text(
                  step.detail,
                  style: AppStyles.bodyMedium.copyWith(
                    fontSize: 12,
                    color: context.textHintColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
