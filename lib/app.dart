import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartbunda/providers/locale_provider.dart';
import 'package:smartbunda/providers/theme_provider.dart';
import 'package:smartbunda/screens/login_screen.dart';
import 'package:smartbunda/screens/food_scan_screen.dart';
import 'package:smartbunda/screens/get_started_screen.dart';
import 'package:smartbunda/screens/nutrition_facts_screen.dart';
import 'package:smartbunda/screens/register_screen.dart';
import 'package:smartbunda/screens/splash_screen.dart';
import 'package:smartbunda/theme/app_theme.dart';
import 'package:smartbunda/widgets/nutrition_slider.dart';

class SmartbundaApp extends ConsumerWidget {
  const SmartbundaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    return MaterialApp(
      title: 'Smartbunda',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode.themeMode,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ms'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashGate(),
      routes: {
        GetStartedScreen.routeName: (context) => const GetStartedScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        RegisterScreen.routeName: (context) => const RegisterScreen(),
        NutritionFactsScreen.routeName: (context) =>
            const NutritionFactsScreen(),
        FoodScanScreen.routeName: (context) => const FoodScanScreen(),
        '/onboarding': (context) => const NutritionSlider(),
      },
    );
  }
}
