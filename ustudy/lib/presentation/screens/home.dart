import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustudy/presentation/blocs/auth/auth_bloc.dart';
import 'package:ustudy/presentation/blocs/auth/auth_state.dart';
import 'package:ustudy/presentation/widgets/home/chat_icon.dart';
import 'package:ustudy/presentation/widgets/home/chat_summary.dart';
import 'package:ustudy/presentation/widgets/home/top_nav_bar.dart';
import 'package:ustudy/presentation/widgets/home/announcements.dart';
import 'package:ustudy/presentation/screens/chat/talkiebot.dart';
import 'package:ustudy/presentation/screens/resources/resources.dart';
import 'package:ustudy/presentation/screens/tasks/tasks.dart';
import 'package:ustudy/presentation/screens/profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentTabIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentTabIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      // Home
      SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                "Do you need to talk to someone?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ChatSummaryCard(),
            SizedBox(height: 24),
            AnnouncementsWidget(),
          ],
        ),
      ),

      // Resources
      const ResourcesScreen(),

      // Homework
      BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return TareasScreen(usuarioId: state.usuario.localId);
          }
          return const Center(child: Text("Please log in."));
        },
      ),

      // Profile
      const ProfileScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopNavbar(
              currentIndex: _currentTabIndex,
              onTabSelected: _onTabSelected,
              tabs: const ['Home', 'Resources', 'Homework', 'Profile'],
            ),
            const Divider(height: 1),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentTabIndex = index;
                  });
                },
                physics: const NeverScrollableScrollPhysics(),
                children: pages,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatScreen()),
          );
        },
        child: const ChatIcon(color: Colors.black),
      ),
    );
  }
}
