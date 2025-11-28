import 'package:google_sign_in/google_sign_in.dart';

abstract class GoogleAuthDataSource {
  Future<String?> signInWithGoogle(); 
  Future<void> signOut();
}

class GoogleAuthDataSourceImpl implements GoogleAuthDataSource {
  final GoogleSignIn _googleSignIn;

  GoogleAuthDataSourceImpl({
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn(
    scopes: ['email'],
    signInOption: SignInOption.standard,
  );

  @override
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      return googleUser.email;
    } catch (e) {
      throw Exception('Error al iniciar sesión con Google: $e');
    }
  }

  @override
 Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }
} 