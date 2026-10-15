import 'package:afromessage_dart/afromessage_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const _primary = Color(0xFF3F51B5);
const _bg = Color(0xFFF2F3F7);
const _muted = Color(0xFF9AA0B0);
const _ink = Color(0xFF1C1F2A);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env optional for local runs.
  }
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'afromessage_dart demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: _bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.light,
          primary: _primary,
          surface: Colors.white,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _primary,
            minimumSize: const Size.fromHeight(50),
            side: const BorderSide(color: _primary, width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _bg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _primary, width: 1.4),
          ),
          labelStyle: const TextStyle(color: _muted),
          floatingLabelStyle: const TextStyle(color: _primary),
        ),
      ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  final _senderController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController(
    text: 'Hello from afromessage_dart',
  );
  final _otpCodeController = TextEditingController();

  String _apiKey = '';
  int _tabIndex = 0;
  bool _busy = false;
  String _smsResult = '';
  String _otpResult = '';
  String _verifyResult = '';
  String? _normalizedPreview;

  bool get _hasApiKey => _apiKey.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _apiKey = _envValue('API_Key') ?? _envValue('AFROMESSAGE_TOKEN') ?? '';

    final sender = _envValue('AFROMESSAGE_SENDER_NAMES') ??
        _envValue('SENDER_NAME') ??
        _envValue('AFROMESSAGE_SENDER_NAME');
    if (sender != null) _senderController.text = sender;

    final phone = _envValue('PHONE') ??
        _envValue('AFROMESSAGE_PHONE') ??
        _envValue('PHONE_NUMBER');
    _phoneController.text = phone ?? '0956291689';
    _refreshNormalizedPreview();
  }

  String? _envValue(String key) {
    if (!dotenv.isInitialized) return null;
    final value = dotenv.maybeGet(key)?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  @override
  void dispose() {
    _senderController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    _otpCodeController.dispose();
    super.dispose();
  }

  void _refreshNormalizedPreview() {
    final raw = _phoneController.text.trim();
    if (raw.isEmpty) {
      setState(() => _normalizedPreview = null);
      return;
    }
    try {
      setState(() => _normalizedPreview = normalizeEthiopianPhone(raw));
    } on AfroMessageException catch (e) {
      setState(() => _normalizedPreview = e.message);
    }
  }

  AfroMessage _client() {
    if (!_hasApiKey) {
      throw AfroMessageException(
        'API key missing. Add API_Key to demo_app/.env and restart.',
      );
    }
    return AfroMessage(
      AfroMessageConfig(
        apiKey: _apiKey,
        senderName: _senderController.text.trim(),
      ),
    );
  }

  Future<void> _sendSms() async {
    setState(() {
      _busy = true;
      _smsResult = '';
    });
    try {
      final to = normalizeEthiopianPhone(_phoneController.text);
      final message = _messageController.text.trim();
      if (message.isEmpty) {
        throw AfroMessageException('Message is required.');
      }
      final client = _client();
      try {
        final result = await client.sendSms(
          SendSmsRequest(to: to, message: message),
        );
        setState(() {
          if (result.isSuccess) {
            _smsResult = 'Sent\n'
                'message_id: ${result.response?.messageId}\n'
                'to: ${result.response?.to}';
          } else {
            _smsResult =
                'Failed\n${result.error ?? result.raw?.toString() ?? 'unknown'}';
          }
        });
      } finally {
        client.close();
      }
    } on AfroMessageException catch (e) {
      setState(() => _smsResult = 'Error: $e');
    } catch (e) {
      setState(() => _smsResult = 'Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _sendOtp() async {
    setState(() {
      _busy = true;
      _otpResult = '';
    });
    try {
      final to = normalizeEthiopianPhone(_phoneController.text);
      final client = _client();
      try {
        final result = await client.sendSecurityCode(
          SendSecurityCodeRequest(
            to: to,
            length: 6,
            postfix: 'is your verification code',
            spacesAfter: 1,
          ),
        );
        setState(() {
          _otpResult = result.isSuccess
              ? 'OTP sent\n'
                  'verificationId: ${result.response?.verificationId}\n'
                  'message_id: ${result.response?.messageId}'
              : 'Failed\n${result.response?.message ?? 'unknown'}';
        });
      } finally {
        client.close();
      }
    } on AfroMessageException catch (e) {
      setState(() => _otpResult = 'Error: $e');
    } catch (e) {
      setState(() => _otpResult = 'Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _busy = true;
      _verifyResult = '';
    });
    try {
      final to = normalizeEthiopianPhone(_phoneController.text);
      final code = _otpCodeController.text.trim();
      if (code.isEmpty) {
        throw AfroMessageException('Enter the OTP code to verify.');
      }
      final client = _client();
      try {
        final result = await client.verifyCode(
          VerifyCodeRequest(to: to, code: code),
        );
        setState(() {
          _verifyResult = result.isSuccess
              ? 'Verified\nphone: ${result.response?.phone}'
              : 'Failed\n${result.error ?? 'invalid code'}';
        });
      } finally {
        client.close();
      }
    } on AfroMessageException catch (e) {
      setState(() => _verifyResult = 'Error: $e');
    } catch (e) {
      setState(() => _verifyResult = 'Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AfroMessage',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        Text(
                          'Live SMS & OTP demo',
                          style: TextStyle(
                            fontSize: 13,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ApiKeyFlag(loaded: _hasApiKey),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: _PillTabBar(
                index: _tabIndex,
                labels: const ['SMS', 'OTP'],
                onChanged: _busy ? null : (i) => setState(() => _tabIndex = i),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _InfoTile(
                        icon: Icons.phone_iphone_rounded,
                        iconBg: const Color(0xFFE8EAF6),
                        title: 'Recipient',
                        subtitle: _normalizedPreview ??
                            _phoneController.text.trim().ifEmpty('No phone'),
                        trailing: Icon(
                          _hasApiKey ? Icons.check_circle : Icons.error_outline,
                          color: _hasApiKey
                              ? const Color(0xFF22C55E)
                              : Colors.redAccent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _phoneController,
                        enabled: !_busy,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => _refreshNormalizedPreview(),
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          hintText: 'From .env PHONE or edit here',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _senderController,
                        enabled: !_busy,
                        decoration: const InputDecoration(
                          labelText: 'Sender name',
                          hintText: 'From .env or dashboard',
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_tabIndex == 0)
                        _buildSmsPanel()
                      else
                        _buildOtpPanel(),
                      if (_busy) ...[
                        const SizedBox(height: 20),
                        const Center(
                          child: CircularProgressIndicator(color: _primary),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _messageController,
          enabled: !_busy,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Message',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : _sendSms,
          icon: const Icon(Icons.send_rounded),
          label: const Text('Send SMS'),
        ),
        _ResultBox(text: _smsResult),
      ],
    );
  }

  Widget _buildOtpPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: _busy ? null : _sendOtp,
          icon: const Icon(Icons.lock_outline_rounded),
          label: const Text('Send OTP'),
        ),
        _ResultBox(text: _otpResult),
        const SizedBox(height: 8),
        TextField(
          controller: _otpCodeController,
          enabled: !_busy,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'OTP code',
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _busy ? null : _verifyOtp,
          icon: const Icon(Icons.verified_outlined),
          label: const Text('Verify OTP'),
        ),
        _ResultBox(text: _verifyResult),
      ],
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}

class _ApiKeyFlag extends StatelessWidget {
  const _ApiKeyFlag({required this.loaded});

  final bool loaded;

  @override
  Widget build(BuildContext context) {
    final bg = loaded ? const Color(0xFFE8F8EF) : const Color(0xFFFFEBEE);
    final fg = loaded ? const Color(0xFF15803D) : const Color(0xFFC62828);
    final label = loaded ? 'API key loaded' : 'API key missing';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            loaded ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: fg,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillTabBar extends StatelessWidget {
  const _PillTabBar({
    required this.index,
    required this.labels,
    required this.onChanged,
  });

  final int index;
  final List<String> labels;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE7E9F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: onChanged == null ? null : () => onChanged!(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: index == i ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: index == i
                        ? const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight:
                          index == i ? FontWeight.w700 : FontWeight.w500,
                      color: index == i ? _primary : _muted,
                      fontSize: 14,
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}

class _ResultBox extends StatelessWidget {
  const _ResultBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox(height: 12);

    final isError = text.startsWith('Error:') ||
        text.startsWith('Failed') ||
        text.contains('acknowledge: error');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFF1F2) : const Color(0xFFEEF0FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SelectableText(
        text,
        style: TextStyle(
          color: isError ? const Color(0xFF991B1B) : _ink,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }
}
