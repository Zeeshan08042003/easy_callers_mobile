import 'package:flutter/material.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/core/models/lead_model.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';

class LeadCard extends StatelessWidget {
  final LeadModel lead;
  final VoidCallback? onTap;
  final VoidCallback? onActionPressed;

  const LeadCard({
    super.key,
    required this.lead,
    this.onTap,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161C28),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${lead.projectName ?? "General Inquiry"} - ${lead.budget ?? "N/A"}',
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      'https://i.pravatar.cc/150?u=${lead.assignedTo ?? lead.id}',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    lead.assignedToName ?? 'Unassigned',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildIconButton(Icons.more_horiz, () {}),
                  const SizedBox(width: 12),
                  if (lead.status == LeadStatus.connected) // For "No Answer" case
                    _buildReassignButton()
                  else
                    _buildActionButton(),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String label;

    switch (lead.status) {
      case LeadStatus.followUp:
        color = const Color(0xFFF97316);
        label = 'FOLLOW-UP DUE';
        break;
      case LeadStatus.newLead:
        color = const Color(0xFF3B82F6);
        label = 'NEW LEAD';
        break;
      case LeadStatus.interested:
        color = const Color(0xFF10B981);
        label = 'VISIT TOMORROW';
        break;
      case LeadStatus.connected:
        color = const Color(0xFF94A3B8);
        label = 'NO ANSWER (3X)';
        break;
      default:
        color = AppColors.textSecondary;
        label = lead.status.value.toUpperCase().replaceAll('_', ' ');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF242C3B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white.withOpacity(0.7), size: 22),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildActionButton() {
    IconData icon;
    Color color = AppColors.primary;

    if (lead.status == LeadStatus.followUp) {
      icon = Icons.send_rounded;
    } else if (lead.status == LeadStatus.newLead) {
      icon = Icons.assignment_ind_rounded;
    } else if (lead.status == LeadStatus.interested) {
      icon = Icons.calendar_today_rounded;
    } else {
      icon = Icons.phone_rounded;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 22),
        onPressed: onActionPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildReassignButton() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2432).withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Text(
          'Reassign',
          style: TextStyle(
            color: Color(0xFF3B82F6),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
