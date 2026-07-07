import 'package:firebase_auth/firebase_auth.dart';

/// 인증 관련 로직을 한곳에 모은 서비스.
/// 화면 코드는 FirebaseAuth를 직접 만지지 말고 이 클래스만 사용할 것.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 현재 로그인된 사용자 (없으면 null)
  User? get currentUser => _auth.currentUser;

  /// 로그인 상태 변화 스트림 (자동 로그인 분기에 사용)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 이메일 회원가입
  Future<UserCredential> signUp(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// 이메일 로그인
  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// 로그아웃
  Future<void> signOut() => _auth.signOut();

  /// FirebaseAuthException 코드 → 사용자에게 보여줄 한국어 메시지
  static String messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return '이메일 형식이 올바르지 않습니다.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return '이메일 또는 비밀번호가 일치하지 않습니다.';
      case 'email-already-in-use':
        return '이미 가입된 이메일입니다.';
      case 'weak-password':
        return '비밀번호는 6자 이상이어야 합니다.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해주세요.';
      default:
        return '오류가 발생했습니다. 잠시 후 다시 시도해주세요. (${e.code})';
    }
  }
}