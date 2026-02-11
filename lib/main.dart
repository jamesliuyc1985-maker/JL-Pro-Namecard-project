import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/crm_provider.dart';
import 'services/data_service.dart';
import 'services/notification_service.dart';
import 'utils/theme.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize DataService (local in-memory with built-in data)
  final dataService = DataService();
  await dataService.init();

  runApp(DealNavigatorApp(dataService: dataService));
}

class DealNavigatorApp extends StatelessWidget {
  final DataService dataService;
  const DealNavigatorApp({super.key, required this.dataService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final ns = NotificationService();
          final crm = CrmProvider(dataService);
          crm.setNotificationService(ns);
          crm.loadAll();
          return crm;
        }),
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
      child: Builder(builder: (context) {
        final crm = context.read<CrmProvider>();
        final ns = context.read<NotificationService>();
        crm.setNotificationService(ns);

        return MaterialApp(
          title: 'Deal Navigator',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        );
      }),
    );
  }
}
