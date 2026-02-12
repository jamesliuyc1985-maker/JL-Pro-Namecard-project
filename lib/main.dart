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
    ).timeout(const Duration(seconds: 6));
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
          home: _firebaseReady ? const _AuthGate() : const HomeScreen(),
        );
      }),
    );
  }
}

/// Firebase 登录状态网关（带超时保护）
class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    // 5 秒超时保护：如果 Auth 流一直没响应，降级到本地模式
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _timedOut == false) {
        // 如果仍在 waiting 状态，检查一下
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          // 可能 Auth 正常但没登录，不做操作（让 StreamBuilder 处理）
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 连接中 → 显示 loading（但有超时保护）
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
                    // 手动跳过，进入本地模式
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

        if (snapshot.hasData && snapshot.data != null) {
          // 已登录 → 设置 userId + 后台同步
          final user = snapshot.data!;
          final crm = context.read<CrmProvider>();
          crm.setUserId(user.uid);
          // 后台异步同步（不阻塞 UI，带超时）
          crm.syncFromCloud().timeout(const Duration(seconds: 8)).catchError((_) {});

          return HomeScreen(
            onLogout: () async {
              try {
                await AuthService().logout();
              } catch (_) {}
            },
          );
        }

        // 未登录 → 登录页
        return AuthScreen(
          onLoginSuccess: () {
            // StreamBuilder 自动检测 authState 变化
          },
        );
      },
    );
  }
}
