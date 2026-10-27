import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase can be optionally initialized here if SUPABASE_URL and ANON_KEY are provided.
  // LIFESYNC runs completely offline and locally in memory by default with zero external dependencies.

  runApp(
    const ProviderScope(
      child: LifeSyncApp(),
    ),
  );
}
