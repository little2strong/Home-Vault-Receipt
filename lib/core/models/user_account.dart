enum SignInMethod {
  email('Email'),
  apple('Apple'),
  google('Google');

  const SignInMethod(this.label);

  final String label;
}

class UserAccount {
  const UserAccount({
    required this.id,
    required this.email,
    required this.createdAt,
    this.name,
    this.emailVerified = false,
    this.methods = const {SignInMethod.email},
  });

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
    id: json['id'] as String,
    email: json['email'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    name: json['name'] as String?,
    emailVerified: json['email_verified'] as bool? ?? false,
    methods: {
      for (final m in json['methods'] as List? ?? const ['email'])
        SignInMethod.values.byName(m as String),
    },
  );

  final String id;
  final String email;
  final String? name;
  final bool emailVerified;
  final Set<SignInMethod> methods;
  final DateTime createdAt;

  String get displayName {
    final n = name?.trim() ?? '';
    return n.isNotEmpty ? n : email.split('@').first;
  }

  UserAccount copyWith({
    String? name,
    bool? emailVerified,
    Set<SignInMethod>? methods,
  }) => UserAccount(
    id: id,
    email: email,
    createdAt: createdAt,
    name: name ?? this.name,
    emailVerified: emailVerified ?? this.emailVerified,
    methods: methods ?? this.methods,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'created_at': createdAt.toIso8601String(),
    'name': name,
    'email_verified': emailVerified,
    'methods': [for (final m in methods) m.name],
  };
}

class DeviceSession {
  const DeviceSession({
    required this.id,
    required this.name,
    required this.lastActive,
    this.location,
    this.isCurrent = false,
  });

  factory DeviceSession.fromJson(Map<String, dynamic> json) => DeviceSession(
    id: json['id'] as String,
    name: json['name'] as String,
    lastActive: DateTime.parse(json['last_active'] as String),
    location: json['location'] as String?,
    isCurrent: json['is_current'] as bool? ?? false,
  );

  final String id;
  final String name;
  final String? location;
  final DateTime lastActive;
  final bool isCurrent;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'last_active': lastActive.toIso8601String(),
    'location': location,
    'is_current': isCurrent,
  };
}
