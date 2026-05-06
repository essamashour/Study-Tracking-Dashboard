import 'package:firebase_auth/firebase_auth.dart';
import 'local_storage_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalStorageService _localStorage = LocalStorageService();

  Future<User?> signUp(String name, String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(name);
    await _localStorage.prepareForUser(credential.user?.uid);
    return credential.user;
  }

  Future<User?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _localStorage.prepareForUser(credential.user?.uid);
    return credential.user;
  }

  Future<void> tryRestoreSession() async {
    await _localStorage.prepareForUser(_auth.currentUser?.uid);
  }

  Future<void> signOut() async {
    await _localStorage.prepareForUser(null);
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
