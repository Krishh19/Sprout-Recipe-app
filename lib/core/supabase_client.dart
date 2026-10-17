import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        headers: const {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
      );
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Supabase initialization error: $e');
    }
  }

  static Future<void> signInAnonymouslyIfNeeded() async {
    try {
      final session = client.auth.currentSession;
      if (session == null) {
        await client.auth.signInAnonymously();
        debugPrint('Signed in anonymously: ${client.auth.currentUser?.id}');
      }
    } catch (e) {
      debugPrint('Anonymous auth warning: $e');
    }
  }
}
