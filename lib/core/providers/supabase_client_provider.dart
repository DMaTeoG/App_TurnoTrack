import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final sessionStreamProvider = StreamProvider<Session?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange.map((data) => data.session);
});

final currentSessionProvider = Provider<Session?>((ref) {
  final asyncSession = ref.watch(sessionStreamProvider);
  return asyncSession.value ?? Supabase.instance.client.auth.currentSession;
});

