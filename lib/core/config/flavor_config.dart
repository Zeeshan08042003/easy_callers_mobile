class FlavorConfig {
  final String name;
  final Map<String, dynamic> variables;

  static FlavorConfig? _instance;

  FlavorConfig({
    required this.name,
    required this.variables,
  }) {
    _instance = this;
  }

  static FlavorConfig get instance {
    if (_instance == null) {
      throw Exception('FlavorConfig not initialized.');
    }
    return _instance!;
  }

  String get supabaseUrl => variables['supabaseUrl'] as String;
  String get supabaseAnonKey => variables['supabaseAnonKey'] as String;
  
  static bool get isProd => instance.name == 'prod';
  static bool get isBeta => instance.name == 'beta';
}
