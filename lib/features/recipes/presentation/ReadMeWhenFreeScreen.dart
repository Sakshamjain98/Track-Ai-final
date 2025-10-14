import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackai/core/constants/appcolors.dart';
import 'package:trackai/core/themes/theme_provider.dart';
import 'dart:math';

class ReadMeWhenFreeScreen extends StatefulWidget {
  const ReadMeWhenFreeScreen({Key? key}) : super(key: key);

  @override
  State<ReadMeWhenFreeScreen> createState() => _ReadMeWhenFreeScreenState();
}

class _ReadMeWhenFreeScreenState extends State<ReadMeWhenFreeScreen>
    with SingleTickerProviderStateMixin {

  PageController _pageController = PageController();
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkTheme = themeProvider.isDarkMode;
        final screenWidth = MediaQuery.of(context).size.width;

        return Scaffold(
          backgroundColor: AppColors.background(isDarkTheme),
          body: SafeArea(
            child: Column(
              children: [
                // Enhanced Header
                _buildHeader(isDarkTheme, screenWidth),

                // Content Pages
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemCount: _wisdomContent.length,
                      itemBuilder: (context, index) {
                        return _buildContentPage(_wisdomContent[index], isDarkTheme, screenWidth);
                      },
                    ),
                  ),
                ),

                // Page Indicator & Navigation
                _buildBottomNavigation(isDarkTheme, screenWidth),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDarkTheme, double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.withOpacity(0.1),
            Colors.indigo.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.textSecondary(isDarkTheme).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textSecondary(isDarkTheme).withOpacity(0.2),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.textPrimary(isDarkTheme),
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.deepPurple, Colors.indigo],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.auto_stories, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Read Me When Free',
                        style: TextStyle(
                          color: AppColors.textPrimary(isDarkTheme),
                          fontSize: screenWidth < 400 ? 18 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Ancient wisdom for modern minds • ${_wisdomContent.length} readings',
                  style: TextStyle(
                    color: AppColors.textSecondary(isDarkTheme),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Random button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.deepOrange],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _goToRandomPage,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shuffle, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Random',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentPage(WisdomContent content, bool isDarkTheme, double screenWidth) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.05),
      child: Column(
        children: [
          // Content Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(screenWidth * 0.06),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.cardBackground(isDarkTheme),
                  AppColors.cardBackground(isDarkTheme).withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: content.accentColor.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkTheme ? 0.3 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and source
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [content.accentColor, content.accentColor.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: content.accentColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(content.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            content.source,
                            style: TextStyle(
                              color: content.accentColor,
                              fontSize: screenWidth < 400 ? 16 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (content.author.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'by ${content.author}',
                              style: TextStyle(
                                color: AppColors.textSecondary(isDarkTheme),
                                fontSize: screenWidth < 400 ? 12 : 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Title
                if (content.title.isNotEmpty) ...[
                  Text(
                    content.title,
                    style: TextStyle(
                      color: AppColors.textPrimary(isDarkTheme),
                      fontSize: screenWidth < 400 ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Content
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: content.accentColor.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: content.accentColor.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    content.text,
                    style: TextStyle(
                      color: AppColors.textPrimary(isDarkTheme),
                      fontSize: screenWidth < 400 ? 16 : 18,
                      height: 1.8,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),

                const SizedBox(height: 20),

                // Reflection section
                if (content.reflection.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          content.accentColor.withOpacity(0.1),
                          content.accentColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: content.accentColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Reflect',
                              style: TextStyle(
                                color: content.accentColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          content.reflection,
                          style: TextStyle(
                            color: AppColors.textSecondary(isDarkTheme),
                            fontSize: 14,
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: content.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: content.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: content.accentColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: content.accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDarkTheme, double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(isDarkTheme).withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_wisdomContent.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == _currentIndex ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == _currentIndex
                      ? _wisdomContent[_currentIndex].accentColor
                      : Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous button
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: _currentIndex > 0
                        ? AppColors.textSecondary(isDarkTheme).withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _currentIndex > 0
                          ? AppColors.textSecondary(isDarkTheme).withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _currentIndex > 0 ? _previousPage : null,
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            color: _currentIndex > 0
                                ? AppColors.textPrimary(isDarkTheme)
                                : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Previous',
                            style: TextStyle(
                              color: _currentIndex > 0
                                  ? AppColors.textPrimary(isDarkTheme)
                                  : Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Current page info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _wisdomContent[_currentIndex].accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} of ${_wisdomContent.length}',
                  style: TextStyle(
                    color: _wisdomContent[_currentIndex].accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Next button
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: _currentIndex < _wisdomContent.length - 1
                        ? AppColors.textSecondary(isDarkTheme).withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _currentIndex < _wisdomContent.length - 1
                          ? AppColors.textSecondary(isDarkTheme).withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _currentIndex < _wisdomContent.length - 1 ? _nextPage : null,
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Next',
                            style: TextStyle(
                              color: _currentIndex < _wisdomContent.length - 1
                                  ? AppColors.textPrimary(isDarkTheme)
                                  : Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: _currentIndex < _wisdomContent.length - 1
                                ? AppColors.textPrimary(isDarkTheme)
                                : Colors.grey,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_currentIndex < _wisdomContent.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToRandomPage() {
    final random = Random();
    int randomIndex = random.nextInt(_wisdomContent.length);
    _pageController.animateToPage(
      randomIndex,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
}

// Data Models
class WisdomContent {
  final String title;
  final String text;
  final String source;
  final String author;
  final String reflection;
  final List<String> tags;
  final IconData icon;
  final Color accentColor;

  WisdomContent({
    required this.title,
    required this.text,
    required this.source,
    this.author = '',
    required this.reflection,
    required this.tags,
    required this.icon,
    required this.accentColor,
  });
}

// Wisdom Content Data
final List<WisdomContent> _wisdomContent = [
  WisdomContent(
    title: "The Nature of Action",
    text: "You have the right to perform your prescribed duty, but do not be attached to the fruits of action. Never consider yourself the cause of the results of your activities, and never be attached to not doing your duty.\n\nWork done as a sacrifice for the Supreme Lord has to be performed; otherwise work causes bondage in this material world. Therefore, O son of Kunti, perform your prescribed duties for His satisfaction, and in that way you will always remain unattached and free from bondage.",
    source: "Bhagavad Gita",
    author: "Lord Krishna",
    reflection: "How can you apply the principle of detached action in your daily work today? What would change if you focused purely on the effort rather than the outcome?",
    tags: ["Action", "Detachment", "Purpose", "Work"],
    icon: Icons.self_improvement,
    accentColor: Colors.orange,
  ),

  WisdomContent(
    title: "The Four Noble Truths",
    text: "Life is suffering. The origin of suffering is attachment and craving. The cessation of suffering is possible through the elimination of attachment. There is a path to the cessation of suffering - the Noble Eightfold Path.\n\nJust as a mother would protect her only child with her life, even so let one cultivate a boundless love towards all beings. Let one's thoughts of boundless love pervade the whole world without any obstruction, without any hatred, without any enmity.",
    source: "Buddhist Teaching",
    author: "Buddha",
    reflection: "Where do you notice attachment creating suffering in your life? How might cultivating boundless love transform your relationships?",
    tags: ["Suffering", "Compassion", "Love", "Truth"],
    icon: Icons.spa,
    accentColor: Colors.teal,
  ),

  WisdomContent(
    title: "The Guest House",
    text: "This being human is a guest house. Every morning a new arrival. A joy, a depression, a meanness, some momentary awareness comes as an unexpected visitor.\n\nWelcome and entertain them all! Even if they're a crowd of sorrows, who violently sweep your house empty of its furniture, still, treat each guest honorably. He may be clearing you out for some new delight.\n\nThe dark thought, the shame, the malice, meet them at the door laughing, and invite them in. Be grateful for whoever comes, because each has been sent as a guide from beyond.",
    source: "Sufi Poetry",
    author: "Rumi",
    reflection: "What emotions are you currently resisting? How might welcoming them change your relationship with difficult feelings?",
    tags: ["Emotions", "Acceptance", "Growth", "Wisdom"],
    icon: Icons.home_outlined,
    accentColor: Colors.purple,
  ),

  WisdomContent(
    title: "Know Thyself",
    text: "The unexamined life is not worth living. Wisdom begins in wonder. I know that I know nothing - and this knowledge is the source of my wisdom.\n\nNo one does wrong willingly. When we truly understand what is good, we naturally choose it. The only true wisdom is in knowing you know nothing, for this opens the door to learning and growth.\n\nCare for your soul above all else, for from it springs everything of value in your life.",
    source: "Ancient Philosophy",
    author: "Socrates",
    reflection: "What assumptions about yourself or your world might you be holding without examination? How might embracing 'not knowing' open new possibilities?",
    tags: ["Self-Knowledge", "Wisdom", "Growth", "Philosophy"],
    icon: Icons.psychology,
    accentColor: Colors.indigo,
  ),

  WisdomContent(
    title: "The Art of Peace",
    text: "When you bow, you should have the feeling of your mind bowing together with your body. You should not bow as a mere form. When you have the feeling of your mind bowing, you have the true calm feeling.\n\nIn your everyday life, you should be mentally prepared to accept whatever happens to you with calmness. When you are mentally prepared, you can easily adapt to any circumstance you encounter.\n\nTrue peace comes not from the absence of conflict, but from the ability to remain centered amidst the storms of life.",
    source: "Zen Teaching",
    author: "Shunryu Suzuki",
    reflection: "Where in your life could you benefit from greater mental preparation and calmness? How might true bowing - of mind and body - change your interactions?",
    tags: ["Peace", "Mindfulness", "Calm", "Preparation"],
    icon: Icons.balance,
    accentColor: Colors.green,
  ),

  WisdomContent(
    title: "The Power of Now",
    text: "Yesterday is history, tomorrow is a mystery, today is a gift. That is why it is called the present.\n\nThe present moment is the only moment available to us, and it is the door to all moments. When we are truly present, we touch the miracle of being alive.\n\nBreathing in, I calm body and mind. Breathing out, I smile. Dwelling in the present moment, I know this is the only moment.",
    source: "Mindfulness Teaching",
    author: "Thich Nhat Hanh",
    reflection: "How much of your day do you spend truly present versus lost in thoughts of past or future? What would shift if you treated this moment as a gift?",
    tags: ["Present", "Mindfulness", "Peace", "Awareness"],
    icon: Icons.access_time,
    accentColor: Colors.blue,
  ),

  WisdomContent(
    title: "The Way of Water",
    text: "Nothing in the world is softer than water, yet nothing is better at overcoming the hard and strong. Water nourishes all things without competing. It flows in places others reject and thus is like the Tao.\n\nThe highest good is like water, which nourishes all things and does not compete. It stays in lowly places that others reject. This is why it is so near to the Tao.\n\nBe content with what you have; rejoice in the way things are. When you realize there is nothing lacking, the whole world belongs to you.",
    source: "Tao Te Ching",
    author: "Lao Tzu",
    reflection: "Where in your life are you trying to force outcomes instead of flowing like water? How might accepting 'what is' open new paths forward?",
    tags: ["Flow", "Acceptance", "Simplicity", "Nature"],
    icon: Icons.waves,
    accentColor: Colors.lightBlue,
  ),

  WisdomContent(
    title: "The Mirror of Relationships",
    text: "We can never obtain peace in the outer world until we make peace with ourselves. Every person you meet is your mirror - they reflect back to you what you need to see about yourself.\n\nThe cave you fear to enter holds the treasure you seek. What we resist persists, but what we accept transforms.\n\nLove is the recognition of oneness in the world of duality. When you truly love someone, you see yourself in them and them in yourself.",
    source: "Modern Wisdom",
    author: "Carl Jung",
    reflection: "What qualities in others trigger you most? How might these be reflections of unaccepted parts of yourself that hold gifts?",
    tags: ["Relationships", "Mirror", "Love", "Growth"],
    icon: Icons.people_outline,
    accentColor: Colors.pink,
  ),

  WisdomContent(
    title: "The Inner Light",
    text: "Your task is not to seek for love, but merely to seek and find all the barriers within yourself that you have built against it. The light is already there - you just need to remove what's covering it.\n\nThere is a light that shines beyond all things on earth, beyond the heavens, beyond all that exists. This is the light that shines in your heart.\n\nYou are not just the drop in the ocean, but the entire ocean in each drop.",
    source: "Vedantic Wisdom",
    author: "Ancient Sages",
    reflection: "What barriers have you built against love - both giving and receiving it? How might recognizing your true nature change how you see yourself and others?",
    tags: ["Love", "Light", "Unity", "Truth"],
    icon: Icons.lightbulb_outline,
    accentColor: Colors.amber,
  ),

  WisdomContent(
    title: "The Art of Letting Go",
    text: "Holding on to anger is like grasping a hot coal with the intent of throwing it at someone else - you are the one who gets burned.\n\nIn the end, just three things matter: How well we have lived, how well we have loved, how well we have learned to let go.\n\nPain is inevitable, suffering is optional. The difference lies in our attachment to outcomes and our resistance to what is.",
    source: "Buddhist Philosophy",
    author: "Various Teachers",
    reflection: "What are you holding onto that's burning you? How might letting go create space for something better to emerge?",
    tags: ["Letting Go", "Freedom", "Peace", "Wisdom"],
    icon: Icons.cloud_outlined,
    accentColor: Colors.grey,
  ),
];
