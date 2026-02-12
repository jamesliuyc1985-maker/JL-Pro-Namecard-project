import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'providers/crm_provider.dart';
import 'services/data_service.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'utils/theme.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';

/// Firebase 初始化状态
bool _firebaseReady = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase 初始化（带超时容错，失败不阻塞启动）
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
    _firebaseReady = true;
    if (kDebugMode) debugPrint('[Main] Firebase initialized successfully');
  } catch (e) {
    _firebaseReady = false;
    if (kDebugMode) debugPrint('[Main] Firebase init failed (app works in local mode): $e');
  }

  // 2. DataService 初始化（local-first, 总是先加载本地种子数据）
  final dataService = DataService();
  await dataService.init();

  // 3. 如果 Firebase 可用，设置 Firestore 同步
  if (_firebaseReady) {
    dataService.enableFirestore();
  }

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
          home: _firebaseReady ? const _AuthGate() : const HomeScreen(),
        );
      }),
    );
  }
}

/// Firebase 登录状态网关
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.darkBg,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // 已登录 → 设置 userId + 后台同步 Firestore
          final user = snapshot.data!;
          final crm = context.read<CrmProvider>();
          crm.setUserId(user.uid);
          // 后台异步同步 Firestore 数据（不阻塞 UI）
          crm.syncFromCloud();

          return HomeScreen(
            onLogout: () async {
              await AuthService().logout();
            },
          );
        }

        // 未登录 → 登录页
        return AuthScreen(
          onLoginSuccess: () {
            // StreamBuilder 会自动检测到 authState 变化并重建
          },
        );
      },
    );
  }
}
