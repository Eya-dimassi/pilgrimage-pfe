import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

  static const List<_IntroSlideData> _slides = [
    _IntroSlideData(
      imagePath: 'assets/intro/img1.png',
      title: 'Un voyage plus serein',
      description:
          'Retrouvez facilement vos informations utiles, vos reperes de groupe et un acces mobile plus simple tout au long du voyage.',
      accentColor: AppColors.gold,
      backgroundColor: Color.fromARGB(255, 188, 179, 155),
    ),
    _IntroSlideData(
      imagePath: 'assets/intro/img2.png',
      title: 'Un espace pour les guides',
      description:
          'Gardez vos groupes bien encadres, avancez avec une vue claire du terrain et consultez rapidement les details utiles.',
      accentColor: AppColors.green,
      backgroundColor: Color.fromARGB(255, 158, 191, 168),
    ),
    _IntroSlideData(
      imagePath: 'assets/intro/img3.png',
      title: 'Un lien pour les familles',
      description:
          'Offrez un suivi plus rassurant de l experience, avec une interface lisible et adaptee au voyage sacre.',
      accentColor: AppColors.blue,
      backgroundColor: Color.fromARGB(255, 152, 160, 195),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _goPrevious() {
    if (_currentIndex == 0) return;
    _goToPage(_currentIndex - 1);
  }

  void _goNext() {
    if (_currentIndex >= _slides.length - 1) {
      context.go('/login');
      return;
    }
    _goToPage(_currentIndex + 1);
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        color: slide.backgroundColor.withValues(alpha: 0.45),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Sacred Journey Hub',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Passer'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (value) {
                      setState(() {
                        _currentIndex = value;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _PageBuilderWidget(slide: _slides[index]);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => _buildDot(index: index),
                ),
              ),
              const SizedBox(height: 14),
              if (_currentIndex < _slides.length - 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _goPrevious,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.section,
                        foregroundColor: AppColors.text,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 34,
                          vertical: 16,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(22),
                            bottomRight: Radius.circular(22),
                          ),
                        ),
                      ),
                      child: const Text('Retour'),
                    ),
                    ElevatedButton(
                      onPressed: _goNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.text,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 34,
                          vertical: 16,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(22),
                            bottomLeft: Radius.circular(22),
                          ),
                        ),
                      ),
                      child: const Text('Suivant'),
                    ),
                  ],
                )
              else
                Center(
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.text,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text('Commencer'),
                  ),
                ),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }

  AnimatedContainer _buildDot({required int index}) {
    final slide = _slides[_currentIndex];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      margin: const EdgeInsets.only(right: 6),
      height: 6,
      width: _currentIndex == index ? 20 : 6,
      decoration: BoxDecoration(
        color: _currentIndex == index ? slide.accentColor : AppColors.border,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _PageBuilderWidget extends StatelessWidget {
  const _PageBuilderWidget({required this.slide});

  final _IntroSlideData slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 6),
          _IllustrationStage(slide: slide),
          const SizedBox(height: 14),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              slide.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IllustrationStage extends StatelessWidget {
  const _IllustrationStage({required this.slide});

  final _IntroSlideData slide;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 28,
            child: Container(
              width: 270,
              height: 190,
              decoration: BoxDecoration(
                color: slide.backgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(120),
                  topRight: Radius.circular(82),
                  bottomLeft: Radius.circular(92),
                  bottomRight: Radius.circular(116),
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 54,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: slide.accentColor.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(28),
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(18),
                ),
              ),
            ),
          ),
          Positioned(
            right: 30,
            top: 44,
            child: Container(
              width: 74,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(22),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(32),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(44),
                topRight: Radius.circular(26),
                bottomLeft: Radius.circular(26),
                bottomRight: Radius.circular(44),
              ),
              child: Image.asset(
                slide.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _IllustrationPlaceholder(
                    imagePath: slide.imagePath,
                    accentColor: slide.accentColor,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IllustrationPlaceholder extends StatelessWidget {
  const _IllustrationPlaceholder({
    required this.imagePath,
    required this.accentColor,
  });

  final String imagePath;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, color: accentColor, size: 42),
            const SizedBox(height: 12),
            const Text(
              'Ajoutez votre image dans assets/intro.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              imagePath,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroSlideData {
  const _IntroSlideData({
    required this.imagePath,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.backgroundColor,
  });

  final String imagePath;
  final String title;
  final String description;
  final Color accentColor;
  final Color backgroundColor;
}
