class SupabaseConfig {
  SupabaseConfig._(this.url, this.publishableKey);

  factory SupabaseConfig.fromEnvironment() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    const instructions =
        'Check config.json and run Flutter with '
        '--dart-define-from-file=config.json.';

    if (url.isEmpty || key.isEmpty) {
      throw StateError('Supabase configuration is missing. $instructions');
    }

    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        !uri.host.endsWith('.supabase.co') ||
        uri.host == 'your-project-ref.supabase.co' ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw StateError('Supabase project URL is invalid. $instructions');
    }
    if (!RegExp(r'^sb_publishable_[A-Za-z0-9_-]+$').hasMatch(key)) {
      throw StateError('Supabase publishable key is invalid. $instructions');
    }

    return SupabaseConfig._(uri.origin, key);
  }

  final String url;
  final String publishableKey;
}
