import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wjccvdofojdpgqrdjzoe.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndqY2N2ZG9mb2pkcGdxcmRqem9lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM2NDI3ODMsImV4cCI6MjA1OTIxODc4M30.nLpx6T9HAN1RFPzpLfX9Kq8C9-snNF-9ji_naPqC414',
  );

  runApp(App());
}