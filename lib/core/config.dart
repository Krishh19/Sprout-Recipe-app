class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mbhceqllbamrwlsiimgu.supabase.co',
  );

  // Public Client Key (Anon / Publishable key safe for client distribution with RLS)
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_8x5GkjZstIaA9Buav40usw_NTIGPk5C',
  );

  // Gemini Multimodal AI Key (runs securely in Supabase Edge Function; can be overridden via --dart-define=GEMINI_API_KEY=...)
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  // Groq High-Speed AI Inference Key (runs securely in Supabase Edge Function; can be overridden via --dart-define=GROQ_API_KEY=...)
  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  // Groq Model (default: qwen/qwen3.8-27b)
  static const String groqModel = String.fromEnvironment(
    'GROQ_MODEL',
    defaultValue: 'qwen/qwen3.8-27b',
  );

  // Storage bucket name
  static const String recipeImagesBucket = 'recipe-images';

  // Feature flag for Genkit AI integration (enabled for culinary substitutions)
  static const bool useGenkitSubstitutions = bool.fromEnvironment(
    'USE_GENKIT_SUBSTITUTIONS',
    defaultValue: true,
  );
}
