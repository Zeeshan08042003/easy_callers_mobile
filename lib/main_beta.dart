import 'package:easy_callers_mobile/core/config/flavor_config.dart';
import 'package:easy_callers_mobile/main.dart';

import 'package:flutter/material.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    FlavorConfig(
      name: 'beta',
      variables: {
        'supabaseUrl': 'https://jfxnkwvfxlavtjlfelzb.supabase.co',
        'supabaseAnonKey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpmeG5rd3ZmeGxhdnRqbGZlbHpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxODA1MjIsImV4cCI6MjA4Nzc1NjUyMn0.je075NvtAgNxq9nppGoNZjqkTbrnVkISyWGqiUOwLds',
      },
    );
    
    await bootstrapApp();
  } catch (e) {
    print('Critical Beta Initialization Error: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Failed to start Beta app: $e\n\nPlease check your internet connection or contact support.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
