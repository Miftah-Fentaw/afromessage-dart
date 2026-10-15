import 'package:afromessage_dart/afromessage_dart.dart';
import 'package:flutter/material.dart';

void main() {
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E4F)),
        useMaterial3: true,
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
  final _apiKeyController = TextEditingController();
  final _senderController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController(
    text: 'Hello from afromessage_dart demo',
  );
  final _otpCodeController = TextEditingController();

  bool _mockMode = true;
  bool _busy = false;
  String? _normalizedPreview;
  String _smsResult = '';
  String _otpResult = '';
  String _verifyResult = '';

  @override
  void dispose() {
    _apiKeyController.dispose();
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

  Future<void> _sendSms() async {
    setState(() {
      _busy = true;
      _smsResult = '';
    });
    try {
      final to = normalizeEthiopianPhone(_phoneController.text);
      if (_mockMode) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        setState(() {
          _smsResult =
              'Mock success\nacknowledge: success\nto: $to\nmessage_id: mock-sms-001';
        });
        return;
      }

      final client = _liveClient();
      try {
        final result = await client.sendSms(
          SendSmsRequest(to: to, message: _messageController.text.trim()),
        );
        setState(() {
          _smsResult = result.isSuccess
              ? 'acknowledge: ${result.acknowledge}\n'
                  'message_id: ${result.response?.messageId}\n'
                  'to: ${result.response?.to}'
              : 'acknowledge: ${result.acknowledge}\nerror: ${result.error}';
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
      if (_mockMode) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        setState(() {
          _otpResult =
              'Mock success\nacknowledge: success\nto: $to\ncode: 123456\n'
              'verificationId: mock-vc-001';
          _otpCodeController.text = '123456';
        });
        return;
      }

      final client = _liveClient();
      try {
        final result = await client.sendSecurityCode(
          SendSecurityCodeRequest(
            to: to,
            length: 6,
            postfix: 'is your verification code',
          ),
        );
        setState(() {
          _otpResult = result.isSuccess
              ? 'acknowledge: ${result.acknowledge}\n'
                  'verificationId: ${result.response?.verificationId}\n'
                  'message_id: ${result.response?.messageId}'
              : 'acknowledge: ${result.acknowledge}';
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

      if (_mockMode) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        final ok = code == '123456';
        setState(() {
          _verifyResult = ok
              ? 'Mock success\nacknowledge: success\nphone: $to\ncode: $code'
              : 'Mock failure\nacknowledge: failure\nerror: Invalid code';
        });
        return;
      }

      final client = _liveClient();
      try {
        final result = await client.verifyCode(
          VerifyCodeRequest(to: to, code: code),
        );
        setState(() {
          _verifyResult = result.isSuccess
              ? 'acknowledge: ${result.acknowledge}\n'
                  'phone: ${result.response?.phone}\n'
                  'verificationId: ${result.response?.verificationId}'
              : 'acknowledge: ${result.acknowledge}\nerror: ${result.error}';
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

  AfroMessage _liveClient() {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      throw AfroMessageException(
        'API key is required when Mock mode is off.',
      );
    }
    return AfroMessage(
      AfroMessageConfig(
        apiKey: apiKey,
        senderName: _senderController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('afromessage_dart demo'),
        actions: [
          Row(
            children: [
              Text('Mock mode', style: theme.textTheme.labelLarge),
              Switch(
                value: _mockMode,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _mockMode = value),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Demo only. Call AfroMessage from your backend in production. '
                'Never ship your API key inside a public app.',
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              enabled: !_mockMode && !_busy,
              decoration: const InputDecoration(
                labelText: 'API key',
                border: OutlineInputBorder(),
                helperText: 'Kept in memory only — never saved',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _senderController,
              enabled: !_mockMode && !_busy,
              decoration: const InputDecoration(
                labelText: 'Sender name (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              enabled: !_busy,
              keyboardType: TextInputType.phone,
              onChanged: (_) => _refreshNormalizedPreview(),
              decoration: InputDecoration(
                labelText: 'Phone number',
                hintText: '09… / 07… / +251…',
                border: const OutlineInputBorder(),
                helperText: _normalizedPreview == null
                    ? 'Ethio Telecom or Safaricom'
                    : 'Normalized: $_normalizedPreview',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              enabled: !_busy,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy ? null : _sendSms,
              icon: const Icon(Icons.sms_outlined),
              label: const Text('Send SMS'),
            ),
            _ResultBox(text: _smsResult),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _busy ? null : _sendOtp,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Send OTP'),
            ),
            _ResultBox(text: _otpResult),
            const SizedBox(height: 12),
            TextField(
              controller: _otpCodeController,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'OTP code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : _verifyOtp,
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Verify OTP'),
            ),
            _ResultBox(text: _verifyResult),
            if (_busy) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  const _ResultBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox(height: 8);

    final isError = text.startsWith('Error:') || text.contains('failure');
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError
            ? scheme.errorContainer.withValues(alpha: 0.5)
            : scheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        text,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
