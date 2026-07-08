import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:flutter/material.dart';

import 'services/magazine_service.dart';
import 'theme.dart';
import 'pages/splash_page.dart';
import 'pages/login_welcome_page.dart';
import 'pages/login_email_page.dart';
import 'pages/signup_page.dart';
import 'pages/onboarding_choice_page.dart';
import 'pages/mood_upload_page.dart';
import 'pages/mood_tags_page.dart';
import 'pages/taste_profile_page.dart';
import 'pages/main_shell.dart';
import 'pages/stand_page.dart';
import 'pages/why_issue_page.dart';
import 'pages/reader_page.dart';
import 'pages/interest_page.dart';
import 'pages/explore_page.dart';
import 'pages/create_page.dart';
import 'pages/my_cover_page.dart';
import 'pages/mypage_page.dart';
import 'pages/taste_picker_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // 카탈로그/아티클/발행사 매핑 동기화 — 앱 시작을 막지 않게 비동기 (실패해도 무해)
  MagazineService()
      .syncCatalog()
      .then((_) => MagazineService().syncArticles())
      .then((_) => MagazineService().syncPublishers());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logzine',
      theme: buildAppTheme(),
      routes: {
        '/': (context) => const SplashPage(),
        '/welcome': (context) => const LoginWelcomePage(),
        '/login/email': (context) => const LoginEmailPage(),
        '/signup': (context) => const SignupPage(),
        '/onboarding': (context) => const OnboardingChoicePage(),
        '/onboarding/upload': (context) => const MoodUploadPage(),
        '/onboarding/tags': (context) => const MoodTagsPage(),
        '/onboarding/profile': (context) => const TasteProfilePage(),
        '/main': (context) => const MainShell(),
        '/stand': (context) => const StandPage(),
        '/discover/why': (context) => const WhyIssuePage(),
        '/reader': (context) => const ReaderPage(),
        '/interest': (context) => const InterestPage(),
        '/explore': (context) => const ExplorePage(),
        '/create': (context) => const CreatePage(),
        '/mypage': (context) => const MyPagePage(),
        '/taste': (context) => const TastePickerPage(),
        '/mycover': (context) => const MyCoverPage(),
      },
    );
  }
}
