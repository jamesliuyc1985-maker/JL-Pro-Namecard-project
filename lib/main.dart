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
import 'screens/profile_screen.dart' show appVersion;

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
    if (kDebugMode) debugPrint('[Main] Firebase init failed (local mode): $e');
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
          // 始终显示 AuthGate（如果 Firebase 就绪）
          // AuthGate 内部处理: 未登录→登录页, 已登录→主页
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
        // 连接中 → 显示 loading + 跳过按钮
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppTheme.darkBg,
            body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('正在连接...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                  child: const Text('跳过登录 (本地模式)', style: TextStyle(fontSize: 12)),
                ),
              ]),
            ),
          );
        }

        // 已登录 → 设置 userId + 进入主页
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          final crm = context.read<CrmProvider>();
          crm.setUserId(user.uid);
          // 后台异步同步（不阻塞 UI）
          crm.syncFromCloud().timeout(const Duration(seconds: 8)).catchError((_) {});

          return HomeScreen(
            onLogout: () async {
              try {
                await AuthService().logout();
              } catch (_) {}
            },
          );
        }

        // 未登录 → 显示登录/注册页
        return AuthScreen(
          onLoginSuccess: () {
            // StreamBuilder 自动检测 authState 变化，自动跳转主页
          },
        );
      },
    );
  }
}
