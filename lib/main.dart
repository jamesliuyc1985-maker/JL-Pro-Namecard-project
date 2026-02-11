import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/crm_provider.dart';
import 'services/data_service.dart';
import 'utils/theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://lkwnphfqbnmxhkeedpdg.supabase.co',
    anonKey: 'sb_publishable_QM3oxU--8_XQ3KNTdeUpTQ_epNcMSbI',
  );

  final dataService = DataService();
  await dataService.init();
  runApp(DealNavigatorApp(dataService: dataService));
}

class DealNavigatorApp extends StatelessWidget {
  final DataService dataService;
  const DealNavigatorApp({super.key, required this.dataService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CrmProvider(dataService)..loadAll(),
      child: MaterialApp(
        title: 'Deal Navigator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
