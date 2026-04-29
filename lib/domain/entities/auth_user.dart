enum AuthProvider { anonymous, google, apple }

class User {
  final String uid;
  final String? email;
  final String? displayName;
  final AuthProvider provider;

  User({
    required this.uid,
    this.email,
    this.displayName,
    required this.provider,
  });
}
