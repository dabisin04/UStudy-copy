import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ustudy/domain/entities/announcement.dart';
import 'package:ustudy/infrastructure/utils/session.dart';

class AnnouncementsWidget extends StatefulWidget {
  const AnnouncementsWidget({super.key});

  @override
  State<AnnouncementsWidget> createState() => _AnnouncementsWidgetState();
}

class _AnnouncementsWidgetState extends State<AnnouncementsWidget> {
  List<Announcement> allAnnouncements = [];
  List<Announcement> userAnnouncements = [];
  bool isLoading = true;
  String? userUniversityId;

  @override
  void initState() {
    super.initState();
    loadAnnouncements();
  }

  Future<void> loadAnnouncements() async {
    try {
      // Load all announcements
      final String response = await rootBundle.loadString(
        'assets/data/announcements.json',
      );
      final List<dynamic> data = jsonDecode(response);
      allAnnouncements =
          data.map((json) => Announcement.fromJson(json)).toList()
            ..sort((a, b) => b.date.compareTo(a.date));

      // Get user's university ID
      await _loadUserUniversity();

      // Filter announcements for user's university
      _filterAnnouncementsByUniversity();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserUniversity() async {
    final session = await SessionService.getUserSession();
    if (session != null) {
      setState(() {
        userUniversityId = session['uId']?.isNotEmpty == true
            ? session['uId']
            : null;
      });
    }
  }

  void _filterAnnouncementsByUniversity() {
    if (userUniversityId == null) {
      // If user has no university, show only general announcements
      userAnnouncements = allAnnouncements
          .where((announcement) => announcement.universityId == 'all')
          .toList();
    } else {
      // Show announcements for user's university + general announcements
      userAnnouncements = allAnnouncements
          .where(
            (announcement) =>
                announcement.universityId == userUniversityId ||
                announcement.universityId == 'all',
          )
          .toList();
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'academic':
        return Icons.school;
      case 'technical':
        return Icons.computer;
      case 'event':
        return Icons.event;
      case 'financial':
        return Icons.attach_money;
      case 'services':
        return Icons.local_library;
      case 'health':
        return Icons.health_and_safety;
      case 'facilities':
        return Icons.business;
      case 'general':
        return Icons.announcement;
      default:
        return Icons.announcement;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (userAnnouncements.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Anuncios de la Universidad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userUniversityId == null
                          ? 'Selecciona tu universidad para ver anuncios específicos'
                          : 'No hay anuncios disponibles para tu universidad',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show only the 3 most recent announcements
    final recentAnnouncements = userAnnouncements.take(3).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Anuncios de la Universidad',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/announcements');
                },
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recentAnnouncements.map(
            (announcement) => _buildAnnouncementCard(announcement),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCategoryIcon(announcement.category),
                  color: _getPriorityColor(announcement.priority),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    announcement.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(
                      announcement.priority,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    announcement.priority.toUpperCase(),
                    style: TextStyle(
                      color: _getPriorityColor(announcement.priority),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              announcement.content,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(announcement.date),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (announcement.universityId == 'all')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'GENERAL',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Hoy';
    } else if (difference == 1) {
      return 'Ayer';
    } else if (difference < 7) {
      return 'Hace $difference días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
