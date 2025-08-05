import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/trip_model.dart';
import 'models/user_location.dart';
import 'models/journal_entry.dart';
import 'models/trip_details.dart';
import 'screens/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(TripModelAdapter());
  Hive.registerAdapter(UserLocationAdapter());
  Hive.registerAdapter(JournalEntryAdapter());
  Hive.registerAdapter(TripDetailsAdapter());

  await Hive.openBox('trips');
  await Hive.openBox('journal');
  await Hive.openBox('locations');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TripMate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
