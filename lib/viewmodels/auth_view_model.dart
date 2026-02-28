import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // v7 ile gelen kural: GoogleSignIn sınıfı yalnızca bir kez başlatılmalıdır.
  bool _isGoogleInitialized = false; 

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // --- EMAIL İLE KAYIT ---
  Future<String?> register(String email, String password) async {
    try { 
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _turkishError(e.code);
    }
  }

  // --- EMAIL İLE GİRİŞ ---
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _turkishError(e.code);
    }
  }

  // --- GOOGLE İLE GİRİŞ (v7 API) ---
  Future<String?> signInWithGoogle() async {
    try {
      // 1. Singleton (tekil) instance kullanımı
      final googleSignIn = GoogleSignIn.instance;
      
      // 2. Yeni kural: Başka hiçbir metot çağrılmadan önce initialize() beklenmelidir
      if (!_isGoogleInitialized) {
        await googleSignIn.initialize();
        _isGoogleInitialized = true;
      }

      // 3. signIn() yerine authenticate() kullanımı
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      if (googleUser == null) return 'Google girişi iptal edildi.';

      // 4. await kaldırıldı, senkron veri çekimi
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // 5. accessToken kaldırıldı, Firebase'in çalışması için idToken yeterlidir
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _turkishError(e.code);
    } catch (e) {
      return 'Google girişi başarısız: $e';
    }
  }

  // --- ÇIKIŞ ---
  Future<void> logout() async {
    try {
      // Çıkış yaparken de .instance üzerinden gidiyoruz
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
    notifyListeners();
  }

  // --- TÜRKÇE HATA MESAJLARI ---
  String _turkishError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Hatalı şifre girdiniz.';
      case 'email-already-in-use':
        return 'Bu e-posta zaten kullanımda.';
      case 'weak-password':
        return 'Şifre en az 6 karakter olmalıdır.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'too-many-requests':
        return 'Çok fazla deneme. Lütfen bekleyin.';
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      default:
        return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }
}