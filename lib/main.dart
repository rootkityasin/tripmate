void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(TripModelAdapter());
  Hive.registerAdapter(JournalEntryAdapter());
  Hive.registerAdapter(ChecklistItemAdapter());
  Hive.registerAdapter(UserLocationAdapter());

  await Hive.openBox('trips');
  await Hive.openBox('journal');
  await Hive.openBox('checklist');
  await Hive.openBox('locations');

  runApp(const MyApp());
}
