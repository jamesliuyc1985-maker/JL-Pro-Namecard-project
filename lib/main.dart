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
import 'services/sync_service.dart';
import 'utils/theme.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';

/// Firebase 初始化状态 — 全局可读，可被后台重试更新
bool _firebaseReady = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase 初始化（带超时容错，失败不阻塞启动）
  _firebaseReady = await _initFirebase();

  // 2. SyncService 初始化（Hive 本地持久化）
  final syncService = SyncService();
  await syncService.init();

  // 3. DataService 初始化（内存缓存 + 种子数据）
  final dataService = DataService();
  await dataService.init();

  // 3.5 从 Hive 恢复持久化数据（如果有）
  await dataService.loadFromHive(syncService);

  // 4. 如果 Firebase 可用，启用双向同步
  if (_firebaseReady) {
    dataService.enableFirestore();
    syncService.enableFirestore();
  }

  runApp(DealNavigatorApp(
    dataService: dataService,
    syncService: syncService,
    firebaseReady: _firebaseReady,
  ));
}

/// Firebase 初始化，最多重试 2 次（首次 10s，重试 8s）
Future<bool> _initFirebase() async {
  for (int attempt = 1; attempt <= 2; attempt++) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(Duration(seconds: attempt == 1 ? 10 : 8));
      if (kDebugMode) debugPrint('[Main] Firebase initialized (attempt $attempt)');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[Main] Firebase init attempt $attempt failed: $e');
      if (attempt < 2) await Future.delayed(const Duration(seconds: 1));
    }
  }
  return false;
}

class DealNavigatorApp extends StatefulWidget {
  final DataService dataService;
  final SyncService syncService;
  final bool firebaseReady;
  const DealNavigatorApp({
    super.key,
    required this.dataService,
    required this.syncService,
    required this.firebaseReady,
  });

  @override
  State<DealNavigatorApp> createState() => _DealNavigatorAppState();
}

class _DealNavigatorAppState extends State<DealNavigatorApp> {
  late bool _fbReady;

  @override
  void initState() {
    super.initState();
    _fbReady = widget.firebaseReady;
    // 如果首次启动 Firebase 失败，后台静默重试
    if (!_fbReady) _retryFirebaseInBackground();
  }

  /// 后台静默重试 Firebase 初始化（5 秒后，最多 3 次）
  Future<void> _retryFirebaseInBackground() async {
    for (int i = 1; i <= 3; i++) {
      await Future.delayed(Duration(seconds: 3 + i * 2));
      if (_fbReady) return;
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 8));
        _firebaseReady = true;
        widget.dataService.enableFirestore();
        widget.syncService.enableFirestore();
        if (mounted) setState(() => _fbReady = true);
        if (kDebugMode) debugPrint('[Main] Firebase background retry #$i succeeded');
        return;
      } catch (e) {
        if (kDebugMode) debugPrint('[Main] Firebase background retry #$i failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.syncService),
        ChangeNotifierProvider(create: (_) {
          final ns = NotificationService();
          final crm = CrmProvider(widget.dataService, widget.syncService);
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
          home: _fbReady ? const _AuthGate() : _LocalModeWithRetryBanner(
            onFirebaseReady: () {
              if (mounted) setState(() => _fbReady = true);
            },
          ),
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
                const Text('正在连接 Firebase...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
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

        // 已登录 → 设置 userId + 强制从云端拉取公共数据
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          final crm = context.read<CrmProvider>();
          crm.setUserId(user.uid);
          // 登录后: 先清理本地Hive旧数据，再从云端拉取最新公共数据
          Future.microtask(() async {
            try {
              final sync = context.read<SyncService>();
              await sync.clearLocal(); // 清空本地缓存确保干净
              await crm.syncFromCloud().timeout(const Duration(seconds: 20));
            } catch (_) {}
          });

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

/// 本地模式 + 顶部重连横幅
class _LocalModeWithRetryBanner extends StatefulWidget {
  final VoidCallback onFirebaseReady;
  const _LocalModeWithRetryBanner({required this.onFirebaseReady});
  @override
  State<_LocalModeWithRetryBanner> createState() => _LocalModeWithRetryBannerState();
}

class _LocalModeWithRetryBannerState extends State<_LocalModeWithRetryBanner> {
  bool _retrying = false;

  Future<void> _manualRetry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 10));
      _firebaseReady = true;
      if (mounted) {
        // 启用 Firestore
        final sync = context.read<SyncService>();
        sync.enableFirestore();
        widget.onFirebaseReady();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('连接失败: $e'), backgroundColor: AppTheme.danger, duration: const Duration(seconds: 3)),
        );
      }
    }
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 黄色顶部横幅 — 提示离线
        Material(
          color: AppTheme.warning.withValues(alpha: 0.9),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(children: [
                const Icon(Icons.cloud_off, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Expanded(child: Text(
                  '当前为本地模式 — Firebase 连接失败',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                )),
                if (_retrying)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                else
                  GestureDetector(
                    onTap: _manualRetry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('重新连接', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ]),
            ),
          ),
        ),
        const Expanded(child: HomeScreen()),
      ],
    );
  }
}
