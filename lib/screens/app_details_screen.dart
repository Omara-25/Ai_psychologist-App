import 'package:flutter/material.dart';
import 'dart:math' as math;

class AppDetailsScreen extends StatefulWidget {
  const AppDetailsScreen({super.key});

  @override
  State<AppDetailsScreen> createState() => _AppDetailsScreenState();
}

class _AppDetailsScreenState extends State<AppDetailsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<String> _tabs = ['Overview', 'Features', 'About Us'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              backgroundColor: theme.colorScheme.primary,
              // Add leading back button
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  // First try to pop the current screen
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    // If can't pop, navigate to chat screen using named route
                    Navigator.of(context).pushReplacementNamed('/chat');
                  }
                },
              ),
              flexibleSpace: FlexibleSpaceBar(
                // Remove centerTitle to prevent overlap with the icon
                centerTitle: false,
                title: const Padding(
                  padding: EdgeInsets.only(bottom: 16.0, left: 16.0),
                  child: Text(
                    'AI Psychologist',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Use a custom title position to avoid overlap with tabs
                titlePadding: const EdgeInsets.only(bottom: 70.0),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Animated background
                    AnimatedBackground(isDarkMode: isDarkMode),

                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.primary.withAlpha(76), // 0.3 * 255 = 76
                            theme.colorScheme.primary.withAlpha(178), // 0.7 * 255 = 178
                          ],
                        ),
                      ),
                    ),

                    // App logo - positioned to avoid title overlap
                    Positioned(
                      top: 40, // Move down from the top
                      right: 0,
                      left: 0,
                      child: Center(
                        child: Hero(
                          tag: 'app_logo_details',
                          child: Container(
                            width: 80,
                            height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(51), // 0.2 * 255 = 51
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.psychology,
                            size: 50,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
              // Use a fixed-height tab bar with clear styling
              bottom: TabBar(
                controller: _tabController,
                tabs: _tabs.map((tab) => Container(
                  height: 50,
                  alignment: Alignment.center,
                  child: Text(tab),
                )).toList(),
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withAlpha(178), // 0.7 * 255 = 178
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 16,
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                dividerColor: Colors.transparent,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(context),
            _buildFeaturesTab(context),
            _buildAboutUsTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF8F9FA),
            isDarkMode ? const Color(0xFF121212) : const Color(0xFFE8F0FE),
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome header
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            child: Text(
              'Welcome to AI Psychologist',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          _buildAnimatedCard(
            title: 'Your AI Companion',
            content: 'Your personal AI-powered mental health companion, designed to provide support and guidance whenever you need it.',
            icon: Icons.health_and_safety,
            color: theme.colorScheme.primary,
            delay: 0,
          ),
          _buildAnimatedCard(
            title: 'How It Works',
            content: 'Chat with our AI in text or voice mode. The AI uses advanced natural language processing to understand your concerns and provide helpful responses.',
            icon: Icons.psychology_alt,
            color: theme.colorScheme.secondary,
            delay: 100,
          ),
          _buildAnimatedCard(
            title: 'Privacy First',
            content: 'Your conversations are private and secure. We prioritize your data privacy and implement strong security measures.',
            icon: Icons.security,
            color: Colors.green,
            delay: 200,
          ),
          _buildAnimatedCard(
            title: 'Disclaimer',
            content: 'AI Psychologist is not a replacement for professional mental health services. If you\'re experiencing a crisis, please contact a healthcare professional.',
            icon: Icons.info_outline,
            color: Colors.orange,
            delay: 300,
          ),

          // Extra padding at the bottom
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeaturesTab(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF8F9FA),
            isDarkMode ? const Color(0xFF121212) : const Color(0xFFE8F0FE),
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Features header
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            child: Text(
              'Key Features',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Feature grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildFeatureCard(
                title: 'Text Chat',
                description: 'Communicate with the AI through text messages at any time.',
                icon: Icons.chat_bubble_outline,
                color: theme.colorScheme.primary,
                delay: 0,
              ),
              _buildFeatureCard(
                title: 'Voice Chat',
                description: 'Speak directly to the AI and receive spoken responses.',
                icon: Icons.mic,
                color: theme.colorScheme.secondary,
                delay: 100,
              ),
              _buildFeatureCard(
                title: 'Chat History',
                description: 'Access your previous conversations for reference.',
                icon: Icons.history,
                color: Colors.teal,
                delay: 200,
              ),
              _buildFeatureCard(
                title: 'Dark Mode',
                description: 'Customize the app appearance with light or dark theme.',
                icon: Icons.dark_mode,
                color: Colors.indigo,
                delay: 300,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // List of additional features
          _buildFeatureItem(
            title: 'Multiple Color Themes',
            description: 'Personalize your experience with different color themes.',
            icon: Icons.palette,
            color: Colors.purple,
            delay: 400,
          ),
          _buildFeatureItem(
            title: 'Offline Support',
            description: 'Basic functionality available even without internet connection.',
            icon: Icons.offline_bolt,
            color: Colors.amber.shade700,
            delay: 500,
          ),
          _buildFeatureItem(
            title: 'Data Privacy',
            description: 'Your conversations are encrypted and never shared with third parties.',
            icon: Icons.security,
            color: Colors.green,
            delay: 600,
          ),

          // Extra padding at the bottom
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    {required String title,
    required String description,
    required IconData icon,
    required Color color,
    required int delay}
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withAlpha(51), // 0.2 * 255 = 51
                child: Icon(
                  icon,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutUsTab(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF8F9FA),
            isDarkMode ? const Color(0xFF121212) : const Color(0xFFE8F0FE),
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // About Us header
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            child: Text(
              'About Us',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Team image
          Container(
            height: 200,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.primary.withAlpha(51), // 0.2 * 255 = 51
              // Use a fallback color instead of an image that might not exist
              // image: DecorationImage(
              //   image: AssetImage('assets/images/team.jpg'),
              //   fit: BoxFit.cover,
              // ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Our Team',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      shadows: [
                        Shadow(
                          color: Colors.black.withAlpha(100),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          _buildAnimatedCard(
            title: 'Our Mission',
            content: 'To make mental health support accessible to everyone through innovative AI technology.',
            icon: Icons.volunteer_activism,
            color: theme.colorScheme.primary,
            delay: 0,
          ),
          _buildAnimatedCard(
            title: 'The Team',
            content: 'We are a dedicated team of AI researchers, psychologists, and developers working together to create a helpful mental health companion.',
            icon: Icons.people,
            color: theme.colorScheme.secondary,
            delay: 100,
          ),

          // Contact section with buttons
          Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.withAlpha(51), // 0.2 * 255 = 51
                        child: const Icon(Icons.email, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Contact Us',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Have questions or feedback? Reach out to us:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.email),
                        label: const Text('Email'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.web),
                        label: const Text('Website'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Version info
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI Psychologist v1.0.0',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© 2023 AI Psychologist Team. All rights reserved.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Extra padding at the bottom
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withAlpha(51), // 0.2 * 255 = 51
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13), // 0.05 * 255 = ~13
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: color.withAlpha(51), // 0.2 * 255 = 51
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(description),
          ),
        ),
      ),
    );
  }
}

class AnimatedBackground extends StatefulWidget {
  final bool isDarkMode;

  const AnimatedBackground({super.key, required this.isDarkMode});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: BackgroundPainter(
            animation: _controller,
            isDarkMode: widget.isDarkMode,
          ),
          child: Container(),
        );
      },
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isDarkMode;

  BackgroundPainter({required this.animation, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = isDarkMode ? Colors.blue.shade900 : Colors.blue.shade100;

    final time = animation.value;
    final width = size.width;
    final height = size.height;

    for (int i = 0; i < 5; i++) {
      final offset = i * 0.2;
      final x = width * 0.5 + math.sin((time + offset) * math.pi * 2) * width * 0.3;
      final y = height * 0.5 + math.cos((time + offset) * math.pi * 2) * height * 0.2;
      final radius = width * (0.1 + 0.05 * math.sin(time * math.pi * 2 + i));

      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint..color = (isDarkMode ? Colors.blue : Colors.indigo).withAlpha(26 + 13 * i), // (0.1 + 0.05 * i) * 255
      );
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) => true;
}
