import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _apiBase = String.fromEnvironment('NOVA_API_BASE_URL');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NovaApp());
}

class NovaApp extends StatefulWidget {
  const NovaApp({super.key});
  @override
  State<NovaApp> createState() => _NovaAppState();
}

class _NovaAppState extends State<NovaApp> {
  String _locale = 'fa';
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _locale = p.getString('locale') ?? 'fa');
    });
  }
  void changeLocale(String value) => setState(() => _locale = value);
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'NOVA VPN',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2688FF), brightness: Brightness.dark),
          scaffoldBackgroundColor: const Color(0xFF091321),
          useMaterial3: true,
        ),
        home: NovaSplash(locale: _locale, onLocaleChanged: changeLocale),
      );
}

class Words {
  static const _fa = <String, String>{
    'tagline': 'اینترنت آزاد را با ما تجربه کنید', 'connecting': 'در حال اتصال',
    'connected': 'متصل', 'disconnecting': 'در حال قطع اتصال', 'disconnected': 'قطع',
    'error': 'خطا', 'load': 'در حال دریافت سرورها', 'noApi': 'نشانی سرویس سرورها تنظیم نشده است',
    'noServers': 'در حال حاضر سرور فعالی در دسترس نیست', 'retry': 'تلاش دوباره',
    'chooseCountry': 'انتخاب کشور', 'chooseServer': 'انتخاب سرور', 'settings': 'تنظیمات',
    'connect': 'برای اتصال لمس کنید', 'disconnect': 'برای قطع اتصال لمس کنید',
    'selected': 'سرور انتخاب‌شده', 'unknown': 'موقعیت نامشخص', 'servers': 'سرور',
    'language': 'زبان', 'fa': 'فارسی', 'en': 'English', 'auto': 'اتصال خودکار به آخرین سرور',
    'autostart': 'اتصال هنگام شروع برنامه', 'notification': 'اعلان VPN توسط اندروید مدیریت می‌شود',
    'version': 'نسخه 1.0.0', 'about': 'درباره Nova VPN', 'privacy': 'حریم خصوصی',
    'support': 'پشتیبانی', 'protocol': 'پروتکل', 'none': 'انتخاب نشده', 'invalid': 'پروفایل سرور معتبر نیست',
    'permission': 'مجوز VPN داده نشد', 'timeout': 'مهلت اتصال تمام شد؛ اتصال تأیید نشد',
    'configError': 'دریافت پیکربندی سرور ناموفق بود', 'failure': 'اتصال برقرار نشد',
  };
  static const _en = <String, String>{
    'tagline': 'A safer connection, with NOVA', 'connecting': 'Connecting',
    'connected': 'Connected', 'disconnecting': 'Disconnecting', 'disconnected': 'Disconnected',
    'error': 'Error', 'load': 'Loading servers', 'noApi': 'Server API URL is not configured',
    'noServers': 'No active servers are currently available', 'retry': 'Retry',
    'chooseCountry': 'Choose country', 'chooseServer': 'Choose server', 'settings': 'Settings',
    'connect': 'Tap to connect', 'disconnect': 'Tap to disconnect', 'selected': 'Selected server',
    'unknown': 'Unknown location', 'servers': 'servers', 'language': 'Language',
    'fa': 'فارسی', 'en': 'English', 'auto': 'Reconnect to last selected server',
    'autostart': 'Connect when app starts', 'notification': 'Android manages the VPN notification',
    'version': 'Version 1.0.0', 'about': 'About Nova VPN', 'privacy': 'Privacy',
    'support': 'Support', 'protocol': 'Protocol', 'none': 'Not selected', 'invalid': 'Invalid server profile',
    'permission': 'VPN permission was not granted', 'timeout': 'Connection timed out; connection was not confirmed',
    'configError': 'Could not retrieve server configuration', 'failure': 'Connection failed',
  };
  static String t(String locale, String key) => (locale == 'fa' ? _fa : _en)[key] ?? key;
}

class NovaSplash extends StatefulWidget {
  const NovaSplash({super.key, required this.locale, required this.onLocaleChanged});
  final String locale;
  final ValueChanged<String> onLocaleChanged;
  @override
  State<NovaSplash> createState() => _NovaSplashState();
}
class _NovaSplashState extends State<NovaSplash> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..forward();
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => HomePage(locale: widget.locale, onLocaleChanged: widget.onLocaleChanged)));
    });
  }
  @override
  void dispose() { _timer?.cancel(); _anim.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: FadeTransition(opacity: _anim, child: ScaleTransition(scale: Tween<double>(begin: .8, end: 1).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutBack)), child: Column(mainAxisSize: MainAxisSize.min, children: [const NovaLogo(size: 150), const SizedBox(height: 22), const Text('NOVA VPN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: 4)), const SizedBox(height: 8), const Text('JEYRAN GROUP', style: TextStyle(color: Color(0xFF35D0BA), letterSpacing: 3)), const SizedBox(height: 24), Text(Words.t(widget.locale, 'tagline'))]))));
}

class NovaLogo extends StatelessWidget {
  const NovaLogo({super.key, this.size = 80});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size, child: CustomPaint(painter: _LogoPainter()));
}
class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 160; canvas.save(); canvas.scale(scale);
    final ring = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.4..shader = const LinearGradient(colors: [Color(0xFFB51CFF), Color(0xFF00D9FF)]).createShader(const Rect.fromLTWH(5, 5, 150, 150));
    canvas.drawCircle(const Offset(80, 80), 70, ring);
    final shield = Path()..moveTo(80, 19)..lineTo(132, 39)..lineTo(126, 91)..quadraticBezierTo(118, 125, 80, 148)..quadraticBezierTo(42, 125, 34, 91)..lineTo(28, 39)..close();
    canvas.drawPath(shield, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..shader = const LinearGradient(colors: [Color(0xFFD42CFF), Color(0xFF00DFFF)]).createShader(const Rect.fromLTWH(25, 18, 110, 132)));
    final star = Path()..moveTo(80, 0)..lineTo(87, 19)..lineTo(106, 26)..lineTo(87, 33)..lineTo(80, 52)..lineTo(73, 33)..lineTo(54, 26)..lineTo(73, 19)..close();
    canvas.drawPath(star, Paint()..shader = const LinearGradient(colors: [Color(0xFF00F0FF), Color(0xFF168BFF)]).createShader(const Rect.fromLTWH(54, 0, 52, 52)));
    final text = TextPainter(text: const TextSpan(text: 'N', style: TextStyle(fontSize: 76, fontWeight: FontWeight.w900, color: Color(0xFFB52CFF), shadows: [Shadow(color: Color(0xFF00CFFF), blurRadius: 12)])), textDirection: TextDirection.ltr)..layout();
    text.paint(canvas, Offset(80 - text.width / 2, 42));
    final vpn = TextPainter(text: const TextSpan(text: 'V P N', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 2)), textDirection: TextDirection.ltr)..layout();
    vpn.paint(canvas, Offset(80 - vpn.width / 2, 116)); canvas.restore();
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NovaServer {
  const NovaServer({required this.id, required this.countryCode, required this.name, required this.protocol});
  final String id, countryCode, name, protocol;
  factory NovaServer.fromJson(Map<String, dynamic> j) => NovaServer(id: j['id'].toString(), countryCode: (j['country_code'] ?? '').toString().toUpperCase(), name: (j['name'] ?? '').toString(), protocol: (j['protocol'] ?? '').toString().toUpperCase());
}

class NovaApi {
  static Future<List<NovaServer>> servers() async {
    if (_apiBase.isEmpty) throw StateError('no_api');
    final uri = Uri.parse('$_apiBase/servers');
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) throw HttpException('HTTP ${response.statusCode}');
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw const FormatException('Expected server list');
    return decoded.whereType<Map<String, dynamic>>().map(NovaServer.fromJson).where((s) => s.id.isNotEmpty && s.name.isNotEmpty).toList();
  }
  static Future<String> config(String id) async {
    final response = await http.get(Uri.parse('$_apiBase/servers/${Uri.encodeComponent(id)}/config')).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw HttpException('HTTP ${response.statusCode}');
    final body = jsonDecode(response.body);
    if (body is! Map || body['config'] is! String || (body['config'] as String).isEmpty) throw const FormatException('Invalid config response');
    return body['config'] as String;
  }
}

enum ConnectionPhase { disconnected, connecting, connected, disconnecting, error }
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.locale, required this.onLocaleChanged});
  final String locale;
  final ValueChanged<String> onLocaleChanged;
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  final List<NovaServer> _servers = [];
  late final V2ray _v2ray;
  NovaServer? _selected;
  bool _loading = true, _busy = false, _autoReconnect = false, _autoStart = false;
  String? _loadError, _lastError, _duration;
  ConnectionPhase _phase = ConnectionPhase.disconnected;
  Timer? _connectTimeout;
  bool get _connected => _phase == ConnectionPhase.connected;
  String t(String key) => Words.t(widget.locale, key);
  @override
  void initState() {
    super.initState();
    _v2ray = V2ray(onStatusChanged: _onStatus);
    _loadPreferences();
    _loadServers();
  }
  Future<void> _loadPreferences() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() { _autoReconnect = p.getBool('auto_reconnect') ?? false; _autoStart = p.getBool('auto_start') ?? false; });
  }
  void _onStatus(V2RayStatus status) {
    if (!mounted) return;
    final s = status.state.toLowerCase();
    setState(() {
      _duration = status.duration;
      if (s.contains('disconnect')) { _phase = ConnectionPhase.disconnected; _connectTimeout?.cancel(); }
      else if (s.contains('connect') && !s.contains('connecting')) { _phase = ConnectionPhase.connected; _connectTimeout?.cancel(); _lastError = null; }
      else if (s.contains('connect')) _phase = ConnectionPhase.connecting;
    });
  }
  Future<void> _loadServers() async {
    setState(() { _loading = true; _loadError = null; });
    try {
      final loaded = await NovaApi.servers();
      if (!mounted) return;
      final p = await SharedPreferences.getInstance();
      final saved = p.getString('nova_selected_server');
      setState(() { _servers..clear()..addAll(loaded); _selected = loaded.where((s) => s.id == saved).firstOrNull; _loading = false; });
      if (_autoStart && _autoReconnect && _selected != null) unawaited(_connect());
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _loadError = e is StateError ? 'noApi' : 'loadError'; });
    }
  }
  Future<void> _select(NovaServer server) async {
    if (_busy || _connected) return;
    final p = await SharedPreferences.getInstance();
    await p.setString('nova_selected_server', server.id);
    if (mounted) setState(() { _selected = server; _lastError = null; });
  }
  Future<void> _connect() async {
    final server = _selected;
    if (_busy || _connected || server == null) return;
    setState(() { _busy = true; _phase = ConnectionPhase.connecting; _lastError = null; });
    try {
      final config = await NovaApi.config(server.id);
      // Validate JSON before asking Android to create the VPN service.
      jsonDecode(config);
      await _v2ray.initialize(notificationIconResourceType: 'mipmap', notificationIconResourceName: 'ic_launcher');
      if (!await _v2ray.requestPermission()) throw StateError('permission');
      await _v2ray.startV2Ray(remark: server.name, config: config, blockedApps: null, bypassSubnets: null, proxyOnly: false);
      _connectTimeout?.cancel();
      _connectTimeout = Timer(const Duration(seconds: 25), () {
        if (mounted && _phase == ConnectionPhase.connecting) setState(() { _phase = ConnectionPhase.error; _lastError = 'timeout'; });
      });
    } catch (e) {
      if (mounted) setState(() { _phase = ConnectionPhase.error; _lastError = e is StateError && e.message == 'permission' ? 'permission' : 'failure'; });
    } finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _disconnect() async {
    if (_busy) return;
    setState(() { _busy = true; _phase = ConnectionPhase.disconnecting; });
    try { await _v2ray.stopV2Ray(); }
    catch (_) { if (mounted) setState(() { _phase = ConnectionPhase.error; _lastError = 'failure'; }); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  String _phaseText() {
    switch (_phase) {
      case ConnectionPhase.connecting: return t('connecting');
      case ConnectionPhase.connected: return t('connected');
      case ConnectionPhase.disconnecting: return t('disconnecting');
      case ConnectionPhase.error: return t('error');
      case ConnectionPhase.disconnected: return t('disconnected');
    }
  }
  String _countryName(String code) {
    const names = {'US': 'United States', 'CA': 'Canada', 'DE': 'Germany', 'NL': 'Netherlands', 'GB': 'United Kingdom', 'FI': 'Finland', 'FR': 'France', 'SG': 'Singapore', 'JP': 'Japan', 'SE': 'Sweden', 'RU': 'Russia', 'PL': 'Poland', 'ES': 'Spain', 'CH': 'Switzerland', 'EE': 'Estonia', 'HK': 'Hong Kong', 'CZ': 'Czechia', 'TR': 'Türkiye', 'KR': 'South Korea', 'AT': 'Austria', 'AU': 'Australia', 'RO': 'Romania', 'DK': 'Denmark', 'IN': 'India', 'TH': 'Thailand', 'BE': 'Belgium', 'IT': 'Italy', 'NO': 'Norway'};
    final english = names[code] ?? t('unknown');
    const fa = {'United States':'آمریکا','Canada':'کانادا','Germany':'آلمان','Netherlands':'هلند','United Kingdom':'بریتانیا','Finland':'فنلاند','France':'فرانسه','Singapore':'سنگاپور','Japan':'ژاپن','Sweden':'سوئد','Russia':'روسیه','Poland':'لهستان','Spain':'اسپانیا','Switzerland':'سوئیس','Estonia':'استونی','Hong Kong':'هنگ‌کنگ','Czechia':'چک','Türkiye':'ترکیه','South Korea':'کره جنوبی','Austria':'اتریش','Australia':'استرالیا','Romania':'رومانی','Denmark':'دانمارک','India':'هند','Thailand':'تایلند','Belgium':'بلژیک','Italy':'ایتالیا','Norway':'نروژ'};
    return widget.locale == 'fa' ? (fa[english] ?? english) : english;
  }
  String _flag(String code) {
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(code)) return '🌐';
    return String.fromCharCodes(code.codeUnits.map((c) => c + 127397));
  }
  Future<void> _openCountries() async {
    final codes = _servers.map((s) => s.countryCode.isEmpty ? 'UNKNOWN' : s.countryCode).toSet().toList()..sort();
    final code = await showModalBottomSheet<String>(context: context, isScrollControlled: true, backgroundColor: const Color(0xFF101A2B), builder: (context) => SafeArea(child: ListView(shrinkWrap: true, children: [Padding(padding: const EdgeInsets.all(20), child: Text(t('chooseCountry'), style: Theme.of(context).textTheme.titleLarge)), ...codes.map((c) { final list = _servers.where((s) => (s.countryCode.isEmpty ? 'UNKNOWN' : s.countryCode) == c).toList(); return ListTile(leading: Text(_flag(c)), title: Text(c == 'UNKNOWN' ? t('unknown') : _countryName(c)), subtitle: Text('${list.length} ${t('servers')}'), onTap: () => Navigator.pop(context, c); })])));
    if (code == null || !mounted) return;
    final list = _servers.where((s) => (s.countryCode.isEmpty ? 'UNKNOWN' : s.countryCode) == code).toList();
    final server = await showModalBottomSheet<NovaServer>(context: context, isScrollControlled: true, backgroundColor: const Color(0xFF101A2B), builder: (context) => SafeArea(child: ListView(shrinkWrap: true, children: [Padding(padding: const EdgeInsets.all(20), child: Text(t('chooseServer'), style: Theme.of(context).textTheme.titleLarge)), ...list.asMap().entries.map((e) => ListTile(leading: Text(_flag(code)), title: Text('${t('chooseServer')} ${e.key + 1}'), subtitle: Text('${t('protocol')}: ${e.value.protocol}'), trailing: _selected?.id == e.value.id ? const Icon(Icons.check_circle, color: Color(0xFF35D0BA)) : null, onTap: () => Navigator.pop(context, e.value))) ])));
    if (server != null) await _select(server);
  }
  Future<void> _openSettings() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SettingsPage(locale: widget.locale, onLocaleChanged: widget.onLocaleChanged)));
    if (mounted) { final p = await SharedPreferences.getInstance(); setState(() { _autoReconnect = p.getBool('auto_reconnect') ?? false; _autoStart = p.getBool('auto_start') ?? false; }); }
  }
  @override
  void dispose() { _connectTimeout?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final groups = <String, List<NovaServer>>{};
    for (final s in _servers) { (groups[s.countryCode.isEmpty ? 'UNKNOWN' : s.countryCode] ??= []).add(s); }
    return Scaffold(
      appBar: AppBar(title: const Row(mainAxisSize: MainAxisSize.min, children: [NovaLogo(size: 32), SizedBox(width: 8), Text('NOVA VPN', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5))]), actions: [IconButton(tooltip: t('settings'), onPressed: _openSettings, icon: const Icon(Icons.settings_outlined))]),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(18), children: [
        Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(colors: [Color(0xFF172D43), Color(0xFF102238)]), border: Border.all(color: const Color(0x4435D0BA))), child: Column(children: [const NovaLogo(size: 80), const SizedBox(height: 10), Text(_phaseText(), style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: _connected ? const Color(0xFF35D0BA) : Colors.white)), if (_connected && _duration != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_duration!, style: const TextStyle(fontSize: 24, fontFeatures: [FontFeature.tabularFigures()]))) , if (_lastError != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(t(_lastError!), textAlign: TextAlign.center, style: const TextStyle(color: Colors.orangeAccent))), const SizedBox(height: 18), SizedBox(width: 150, height: 150, child: OutlinedButton(onPressed: _busy ? null : (_connected ? _disconnect : _connect), style: OutlinedButton.styleFrom(shape: const CircleBorder(), side: const BorderSide(color: Color(0xFF35D0BA), width: 2), backgroundColor: const Color(0x2235D0BA)), child: _busy ? const CircularProgressIndicator() : Icon(_connected ? Icons.stop_rounded : Icons.power_settings_new, size: 54, color: const Color(0xFF35D0BA)))), const SizedBox(height: 12), Text(_connected ? t('disconnect') : t('connect'), style: const TextStyle(color: Colors.white60)), const SizedBox(height: 18), OutlinedButton.icon(onPressed: _servers.isEmpty || _connected ? null : _openCountries, icon: const Icon(Icons.public), label: Text(_selected == null ? t('chooseCountry') : '${_flag(_selected!.countryCode)}  ${_selected!.countryCode.isEmpty ? t('unknown') : _countryName(_selected!.countryCode)}  ·  ${_selected!.name}'))])),
        const SizedBox(height: 20),
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator())),
        if (!_loading && _servers.isEmpty) Center(child: Column(children: [Text(_loadError == 'noApi' ? t('noApi') : _loadError == 'loadError' ? t('failure') : t('noServers'), textAlign: TextAlign.center), const SizedBox(height: 12), OutlinedButton(onPressed: _loadServers, child: Text(t('retry')))])),
        if (_servers.isNotEmpty) Text('${t('chooseCountry')} · ${_servers.length} ${t('servers')}', style: Theme.of(context).textTheme.titleMedium),
        ...groups.entries.map((entry) => Card(color: const Color(0xFF101A2B), child: ExpansionTile(leading: Text(_flag(entry.key)), title: Text(entry.key == 'UNKNOWN' ? t('unknown') : _countryName(entry.key)), subtitle: Text('${entry.value.length} ${t('servers')}'), children: entry.value.asMap().entries.map((item) { final s = item.value; return ListTile(enabled: !_connected && !_busy, leading: Radio<String>(value: s.id, groupValue: _selected?.id, onChanged: (_) => _select(s)), title: Text('${t('chooseServer')} ${item.key + 1}'), subtitle: Text('${t('protocol')}: ${s.protocol}'), onTap: () => _select(s)); }).toList()))),
        const SizedBox(height: 12), const Text('JEYRAN GROUP', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, letterSpacing: 2)),
      ])),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.locale, required this.onLocaleChanged});
  final String locale;
  final ValueChanged<String> onLocaleChanged;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}
class _SettingsPageState extends State<SettingsPage> {
  bool _auto = false, _start = false, _ready = false;
  String t(String key) => Words.t(widget.locale, key);
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { final p = await SharedPreferences.getInstance(); if (mounted) setState(() { _auto = p.getBool('auto_reconnect') ?? false; _start = p.getBool('auto_start') ?? false; _ready = true; }); }
  Future<void> _save(String key, bool value) async { final p = await SharedPreferences.getInstance(); await p.setBool(key, value); }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(t('settings'))), body: !_ready ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(18), children: [ListTile(title: Text(t('language')), trailing: DropdownButton<String>(value: widget.locale, items: [DropdownMenuItem(value: 'fa', child: Text(t('fa'))), DropdownMenuItem(value: 'en', child: Text(t('en')))], onChanged: (v) async { if (v == null) return; final p = await SharedPreferences.getInstance(); await p.setString('locale', v); widget.onLocaleChanged(v); if (mounted) setState(() {}); })), SwitchListTile(title: Text(t('auto')), value: _auto, onChanged: (v) { setState(() => _auto = v); _save('auto_reconnect', v); }), SwitchListTile(title: Text(t('autostart')), subtitle: Text(t('notification')), value: _start, onChanged: (v) { setState(() => _start = v); _save('auto_start', v); }), ListTile(title: Text(t('version')), subtitle: const Text('NOVA VPN · JEYRAN GROUP')), ListTile(title: Text(t('about')), subtitle: const Text('NOVA VPN'))]));
}
