import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 1. Lakap (alias) eklendi
import 'package:google_sign_in/google_sign_in.dart' as gSignIn; 

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      // 2. Sınıfların başına gSignIn. eklendi
      final googleSignIn = gSignIn.GoogleSignIn();
      final gSignIn.GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) return 'Google girişi iptal edildi.';

      // 3. Authentication sınıfının başına gSignIn. eklendi
      final gSignIn.GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
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
      // 4. Sınıfın başına gSignIn. eklendi
      await gSignIn.GoogleSignIn().signOut();
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