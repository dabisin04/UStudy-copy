import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ustudy/domain/entities/announcement.dart';
import 'package:ustudy/infrastructure/utils/session.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<Announcement> allAnnouncements = [];
  List<Announcement> userAnnouncements = [];
  List<Announcement> filteredAnnouncements = [];
  bool isLoading = true;
  String selectedCategory = 'all';
  String selectedPriority = 'all';
  String? userUniversityId;

  final List<String> categories = [
    'all',
    'academic',
    'technical',
    'event',
    'financial',
    'services',
    'health',
    'facilities',
    'general',
  ];

  final List<String> priorities = ['all', 'high', 'medium', 'low'];

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

      // Apply initial filters
      _applyFilters();

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

  void _applyFilters() {
    setState(() {
      filteredAnnouncements = userAnnouncements.where((announcement) {
        bool categoryMatch =
            selectedCategory == 'all' ||
            announcement.category == selectedCategory;
        bool priorityMatch =
            selectedPriority == 'all' ||
            announcement.priority == selectedPriority;
        return categoryMatch && priorityMatch;
      }).toList();
    });
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

  String _getCategoryName(String category) {
    switch (category) {
      case 'academic':
        return 'Académico';
      case 'technical':
        return 'Técnico';
      case 'event':
        return 'Eventos';
      case 'financial':
        return 'Financiero';
      case 'services':
        return 'Servicios';
      case 'health':
        return 'Salud';
      case 'facilities':
        return 'Instalaciones';
      case 'general':
        return 'General';
      default:
        return 'General';
    }
  }

  String _getPriorityName(String priority) {
    switch (priority) {
      case 'high':
        return 'Alta';
      case 'medium':
        return 'Media';
      case 'low':
        return 'Baja';
      default:
        return 'General';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Anuncios'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // University info
          if (userUniversityId != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(Icons.school, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mostrando anuncios de tu universidad',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Categoría',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(
                              category == 'all'
                                  ? 'Todas'
                                  : _getCategoryName(category),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value!;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedPriority,
                        decoration: const InputDecoration(
                          labelText: 'Prioridad',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: priorities.map((priority) {
                          return DropdownMenuItem<String>(
                            value: priority,
                            child: Text(
                              priority == 'all'
                                  ? 'Todas'
                                  : _getPriorityName(priority),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPriority = value!;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Announcements list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredAnnouncements.isEmpty
                ? const Center(
                    child: Text(
                      'No hay anuncios que coincidan con los filtros',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredAnnouncements.length,
                    itemBuilder: (context, index) {
                      return _buildAnnouncementCard(
                        filteredAnnouncements[index],
                      );
                    },
                  ),
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
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getCategoryName(announcement.category),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
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
                    _getPriorityName(announcement.priority).toUpperCase(),
                    style: TextStyle(
                      color: _getPriorityColor(announcement.priority),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              announcement.content,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(announcement.date),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Row(
                  children: [
                    if (announcement.universityId == 'all')
                      Container(
                        margin: const EdgeInsets.only(right: 8),
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
                    Text(
                      'ID: ${announcement.id}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
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
