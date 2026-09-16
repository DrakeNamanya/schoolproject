import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_provider.dart';
import '../../core/config.dart';
import '../../theme/tokens.dart';
import '../../widgets/brand.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _id = TextEditingController();
  final _pw = TextEditingController();
  bool _hide = true;

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // Brand header
          Container(
            height: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [TgsColors.maroon500, TgsColors.brick500, TgsColors.maroon600],
                stops: [0, .6, 1],
              ),
            ),
            child: const Stack(
              children: [
                PatternBackdrop(opacity: .10, size: 260),
                Positioned(top: 0, left: 0, right: 0, child: FlagStrip(height: 5)),
              ],
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Crest(size: 52),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppConfig.schoolName, style: TextStyle(fontFamily: TgsFonts.display, fontSize: 20, color: Colors.white)),
                          Text('SCHOOL MANAGEMENT SYSTEM', style: TextStyle(fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w700, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Welcome back.',
                    style: TextStyle(fontFamily: TgsFonts.display, fontSize: 34, color: Colors.white, height: 1),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in with the phone number or email registered with the school.',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 28),

                  // Card
                  TgsCard(
                    padding: const EdgeInsets.all(20),
                    shadow: TgsShadows.sh4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _id,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.username],
                          decoration: const InputDecoration(
                            labelText: 'Phone or email',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _pw,
                          obscureText: _hide,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => _submit(auth),
                          decoration: InputDecoration(
                            labelText: 'Password / PIN',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              onPressed: () => setState(() => _hide = !_hide),
                            ),
                          ),
                        ),
                        if (auth.error != null) ...[
                          const SizedBox(height: 10),
                          Text(auth.error!, style: const TextStyle(fontSize: 12, color: TgsColors.brick600)),
                        ],
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: auth.busy ? null : () => _submit(auth),
                          child: auth.busy
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Sign in'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Contact the school office to reset your PIN.')),
                          ),
                          child: const Text('Forgot PIN?'),
                        ),
                      ],
                    ),
                  ),

                  if (auth.isDemo) ...[
                    const SizedBox(height: 24),
                    const Eyebrow('Demo accounts · no backend configured'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final e in AuthProvider.demoAccounts.entries)
                          ActionChip(
                            avatar: InitialsAvatar(e.value.initials, size: 22),
                            label: Text('${e.key[0].toUpperCase()}${e.key.substring(1)} · ${e.value.roles.map((r) => r.label).join(' + ')}'),
                            onPressed: () => auth.signInDemo(e.key),
                          ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),
                  const Center(
                    child: Text(
                      AppConfig.motto,
                      style: TextStyle(fontFamily: TgsFonts.display, fontStyle: FontStyle.italic, fontSize: 13, color: TgsColors.maroon500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit(AuthProvider auth) => auth.signInWithPassword(_id.text, _pw.text);
}
