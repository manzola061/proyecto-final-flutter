import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rhxirhzykldmjvkuxieg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJoeGlyaHp5a2xkbWp2a3V4aWVnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM4ODYzNDMsImV4cCI6MjA1OTQ2MjM0M30.R4IqEr-7KzkFg459ENvaUwXIQ6gaaqAAHhaodUNdfnU',
  );

  runApp(App());
}