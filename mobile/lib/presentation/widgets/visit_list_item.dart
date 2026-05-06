import 'package:flutter/material.dart';
import '../../data/models/visit_model.dart';
import 'package:intl/intl.dart';

class VisitListItem extends StatelessWidget {
  final VisitModel visit;
  final VoidCallback? onTap;

  const VisitListItem({
    super.key,
    required this.visit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getVisitTypeColor().withOpacity(0.1),
                    child: Icon(
                      _getVisitTypeIcon(),
                      color: _getVisitTypeColor(),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visit.locationName ?? 'Unknown Location',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          visit.constituencyName ?? 'Unknown Constituency',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getVisitTypeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      visit.visitType ?? 'General',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getVisitTypeColor(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(visit.visitDate),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (visit.attendeesCount != null) ...[
                    Icon(Icons.people, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      '${visit.attendeesCount} attendees',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              if (visit.visitPurpose != null && visit.visitPurpose!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  visit.visitPurpose!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getVisitTypeColor() {
    switch (visit.visitType?.toLowerCase()) {
      case 'community_meeting':
      case 'community':
        return Colors.blue;
      case 'inspection':
      case 'site_visit':
        return Colors.orange;
      case 'public_meeting':
      case 'rally':
        return Colors.purple;
      case 'personal':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getVisitTypeIcon() {
    switch (visit.visitType?.toLowerCase()) {
      case 'community_meeting':
      case 'community':
        return Icons.groups;
      case 'inspection':
      case 'site_visit':
        return Icons.engineering;
      case 'public_meeting':
      case 'rally':
        return Icons.campaign;
      case 'personal':
        return Icons.person;
      default:
        return Icons.location_on;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date not available';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
}
