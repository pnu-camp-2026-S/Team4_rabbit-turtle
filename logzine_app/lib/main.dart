import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:flutter/material.dart';

import 'theme.dart';
import 'pages/login_welcome_page.dart';
import 'pages/login_email_page.dart';
import 'pages/signup_page.dart';
import 'pages/mood_upload_page.dart';
import 'pages/mood_tags_page.dart';
import 'pages/taste_profile_page.dart';
import 'pages/main_shell.dart';
import 'pages/why_issue_page.dart';
import 'pages/reader_page.dart';
import 'pages/interest_page.dart';
import 'pages/explore_page.dart';
import 'pages/create_page.dart';
import 'pages/mypage_page.dart';
import 'pages/taste_picker_page.dart';

import 'services/magazine_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await MagazineService().seedIfEmpty();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logzine',
      theme: buildAppTheme(),
      // 첫 화면은 로그인 웰컴 페이지.
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginWelcomePage(),
        '/login/email': (context) => const LoginEmailPage(),
        '/signup': (context) => const SignupPage(),
        '/onboarding/upload': (context) => const MoodUploadPage(),
        '/onboarding/tags': (context) => const MoodTagsPage(),
        '/onboarding/profile': (context) => const TasteProfilePage(),
        '/main': (context) => const MainShell(),
        '/discover/why': (context) => const WhyIssuePage(),
        '/reader': (context) => const ReaderPage(),
        '/interest': (context) => const InterestPage(),
        '/explore': (context) => const ExplorePage(),
        '/create': (context) => const CreatePage(),
        '/mypage': (context) => const MyPagePage(),
        '/taste': (context) => const TastePickerPage(),
      },
    );
  }
}
