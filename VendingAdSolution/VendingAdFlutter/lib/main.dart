import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG  ←  Edit these two lines before building
// ─────────────────────────────────────────────────────────────────────────────
const String kBaseUrl    = 'http://YOUR_SERVER_IP:5000'; // e.g. http://192.168.1.10:5000
const String kDeviceCode = 'TABLET-001';                 // Unique per physical tablet
// ─────────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force landscape fullscreen on the tablet
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const VendingAdApp());
}

// ─── App root ────────────────────────────────────────────────────────────────
class VendingAdApp extends StatelessWidget {
  const VendingAdApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'VendAD Player',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: false),
        home: const PlayerPage(),
      );
}

// ─── Playlist model ───────────────────────────────────────────────────────────
class PlaylistItem {
  final String fileUrl;
  final String fileName;
  const PlaylistItem({required this.fileUrl, required this.fileName});

  factory PlaylistItem.fromJson(Map<String, dynamic> j) =>
      PlaylistItem(fileUrl: j['fileUrl'] as String, fileName: j['fileName'] as String);
}

// ─── Player page ──────────────────────────────────────────────────────────────
class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: kBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  VideoPlayerController? _controller;
  String  _status     = 'Initializing…';
  String? _currentUrl; // URL of the video currently loaded
  bool    _loading    = false;

  Timer? _heartbeatTimer;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _startHeartbeat();
    _fetchAndPlay();
    // Re-check for new campaign assignments every 5 minutes
    _pollTimer = Timer.periodic(const Duration(minutes: 5), (_) => _fetchAndPlay());
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _pollTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // ── Heartbeat ───────────────────────────────────────────────────────────────
  void _startHeartbeat() {
    _sendHeartbeat(); // Send immediately on launch
    _heartbeatTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _sendHeartbeat(),
    );
  }

  Future<void> _sendHeartbeat() async {
    try {
      await _dio.post('/api/heartbeat', data: {'deviceCode': kDeviceCode});
      debugPrint('[Heartbeat] OK');
    } catch (e) {
      debugPrint('[Heartbeat] Failed: $e');
    }
  }

  // ── Fetch → Download → Play ─────────────────────────────────────────────────
  Future<void> _fetchAndPlay() async {
    if (_loading) return;
    setState(() { _loading = true; _status = 'Fetching playlist…'; });

    try {
      final res   = await _dio.get('/api/playlist/$kDeviceCode');
      final items = (res.data as List)
          .map((j) => PlaylistItem.fromJson(j as Map<String, dynamic>))
          .toList();

      if (items.isEmpty) {
        setState(() { _status = 'No media assigned to $kDeviceCode'; _loading = false; });
        return;
      }

      final item = items.first;

      // Skip if the same video is already playing
      if (_currentUrl == item.fileUrl && _controller != null) {
        setState(() { _loading = false; });
        return;
      }

      setState(() { _status = 'Downloading video…'; });
      final localPath = await _downloadVideo(item);
      await _initPlayer(localPath, item.fileUrl);
    } catch (e) {
      setState(() { _status = 'Error: $e'; _loading = false; });
      debugPrint('[Player] Error: $e');
    }
  }

  /// Downloads the video and caches it locally.
  /// Skips download if local file already matches the server URL.
  Future<String> _downloadVideo(PlaylistItem item) async {
    final dir          = await getApplicationDocumentsDirectory();
    final safeFileName = item.fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final localPath    = '${dir.path}/$safeFileName';

    final prefs     = await SharedPreferences.getInstance();
    final cachedUrl = prefs.getString('cached_url_$safeFileName');

    if (cachedUrl == item.fileUrl && File(localPath).existsSync()) {
      debugPrint('[Player] Cache hit: $localPath');
      return localPath;
    }

    debugPrint('[Player] Downloading: ${item.fileUrl}');
    await _dio.download(
      item.fileUrl,
      localPath,
      onReceiveProgress: (received, total) {
        if (total > 0 && mounted) {
          final pct = (received / total * 100).toStringAsFixed(0);
          setState(() { _status = 'Downloading… $pct%'; });
        }
      },
    );

    await prefs.setString('cached_url_$safeFileName', item.fileUrl);
    return localPath;
  }

  /// Initialises the VideoPlayerController and starts looped playback.
  Future<void> _initPlayer(String localPath, String originalUrl) async {
    final oldController = _controller;

    final ctrl = VideoPlayerController.file(File(localPath));
    await ctrl.initialize();
    ctrl.setLooping(true);
    ctrl.setVolume(1.0);

    if (!mounted) { ctrl.dispose(); return; }

    setState(() {
      _controller = ctrl;
      _currentUrl = originalUrl;
      _status     = '';
      _loading    = false;
    });

    ctrl.play();
    oldController?.dispose();
  }

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final ctrl    = _controller;
    final isReady = ctrl != null && ctrl.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Video or splash ─────────────────────────────────────────────────
          if (isReady)
            Center(
              child: AspectRatio(
                aspectRatio: ctrl.value.aspectRatio,
                child: VideoPlayer(ctrl),
              ),
            )
          else
            _SplashScreen(status: _status),

          // ── Status overlay while loading ────────────────────────────────────
          if (_status.isNotEmpty && !isReady)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _status,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Splash / waiting screen ──────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  final String status;
  const _SplashScreen({required this.status});

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: Color(0xFFE8FF3C),
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'VendAD',
                style: TextStyle(
                  color: Color(0xFFE8FF3C),
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                kDeviceCode,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      );
}
