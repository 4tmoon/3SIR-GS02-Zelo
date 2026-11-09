import 'package:flutter/material.dart';

import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';

class _OnboardingPage {
  final String title;
  final String description;
  final String imageAsset;
  final IconData icon;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.imageAsset,
    required this.icon,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = [
    _OnboardingPage(
      title: 'Fotografe o problema',
      description:
          'Viu um buraco, uma calçada quebrada ou um poste apagado? Tire uma foto na hora e registre a ocorrência com endereço e descrição.',
      imageAsset: 'assets/images/rua-com-buraco.jpg',
      icon: Icons.report_problem_outlined,
    ),
    _OnboardingPage(
      title: 'Engajamento comunitário',
      description:
          'Apoie as ocorrências que afetam o seu dia a dia e mostre que muita gente sofre com o mesmo problema.',
      imageAsset: 'assets/images/escolha.jpg',
      icon: Icons.groups_outlined,
    ),
    _OnboardingPage(
      title: 'Solicitação formal',
      description:
          'Quando uma ocorrência atinge 80% de apoio da comunidade local, o sistema gera um ofício formal para a prefeitura.',
      imageAsset: 'assets/images/documento.jpg',
      icon: Icons.description_outlined,
    ),
  ];

  final _pageController = PageController();
  int _currentPage = 0;
  bool _dontShowAgain = false;

  bool get _isLastPage => _currentPage == _pages.length - 1;

  void _goTo(int page) => _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

  Future<void> _finish() async {
    await PreferencesService().saveSkipOnboarding(_dontShowAgain);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _finish, child: const Text('Pular')),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => _OnboardingPageView(page: _pages[index]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _dontShowAgain,
                    onChanged: (value) => setState(() => _dontShowAgain = value ?? false),
                  ),
                  const Text('Não mostrar novamente'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: Row(
                children: [
                  Visibility(
                    visible: _currentPage > 0,
                    maintainSize: true,
                    maintainState: true,
                    maintainAnimation: true,
                    child: OutlinedButton(
                      onPressed: () => _goTo(_currentPage - 1),
                      child: const Text('Voltar'),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isLastPage ? _finish : () => _goTo(_currentPage + 1),
                    child: Text(_isLastPage ? 'Concluir' : 'Avançar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPage page;
  const _OnboardingPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                page.imageAsset,
                height: 230,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  height: 230,
                  width: double.infinity,
                  color: AppColors.primarySoft,
                  child: Icon(page.icon, size: 80, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              page.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}