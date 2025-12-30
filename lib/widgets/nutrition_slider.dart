import 'package:flutter/material.dart';

import '../screens/login_screen.dart';

class NutritionSlider extends StatefulWidget {
  const NutritionSlider({super.key});

  @override
  State<NutritionSlider> createState() => _NutritionSliderState();
}

class _NutritionSliderState extends State<NutritionSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_Slide> _slides = const [
    _Slide(
      title: 'Healthy Nutrition',
      description: 'Get the best food tips for you and your baby.',
      icon: Icons.favorite,
    ),
    _Slide(
      title: 'Track Your Meals',
      description: 'Keep track of what you eat every day.',
      icon: Icons.restaurant_menu,
    ),
    _Slide(
      title: 'Stay Hydrated',
      description: 'Drink plenty of water for a healthy pregnancy.',
      icon: Icons.local_drink,
    ),
  ];

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 400,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(slide.icon, size: 96, color: Colors.pink[400]),
                        const SizedBox(height: 20),
                        Text(
                          slide.title,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink[800],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            slide.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: Colors.pink[600]),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    height: 10,
                    width: _currentPage == index ? 30 : 10,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? Colors.pink : Colors.pink[200],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (_currentPage == _slides.length - 1) {
                    _goToLogin();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[400],
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentPage == _slides.length - 1 ? 'Done' : 'Next',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: _goToLogin,
              child: Text(
                'Skip',
                style: TextStyle(color: Colors.pink[800], fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}
