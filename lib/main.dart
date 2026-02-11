import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'providers/crm_provider.dart';
import 'services/data_service.dart';
import 'services/notification_service.dart';
import 'utils/theme.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize DataService (Firestore)
  final dataService = DataService();
  await dataService.init();

  // Check auth state
  final isLoggedIn = FirebaseAuth.instance.currentUser != null;

  runApp(DealNavigatorApp(dataService: dataService, isLoggedIn: isLoggedIn));
}

class DealNavigatorApp extends StatefulWidget {
  final DataService dataService;
  final bool isLoggedIn;
  const DealNavigatorApp({super.key, required this.dataService, required this.isLoggedIn});
  @override
  State<DealNavigatorApp> createState() => _DealNavigatorAppState();
}

class _DealNavigatorAppState extends State<DealNavigatorApp> {
  late bool _isAuthenticated;

  @override
  void initState() {
    super.initState();
    _isAuthenticated = widget.isLoggedIn;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final ns = NotificationService();
          final crm = CrmProvider(widget.dataService);
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
          home: _isAuthenticated
            ? const HomeScreen()
            : AuthScreen(onAuthenticated: () => setState(() => _isAuthenticated = true)),
        );
      }),
    );
  }
}
