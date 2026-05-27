import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/clinical_widgets.dart';
import '../providers/local_auth_provider.dart';
import '../providers/firebase_auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscurePassword = true;

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerBiometricUnlock();
    });
  }

  Future<void> _triggerBiometricUnlock() async {
    final localAuthState = ref.read(localAuthProvider);
    if (localAuthState.isBiometricAvailable) {
      final success = await ref.read(localAuthProvider.notifier).authenticate(
        localizedReason: 'Scan fingerprint or utilize FaceID to unlock your secure clinical space.',
      );
      if (success && mounted) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final localAuthState = ref.watch(localAuthProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  
                  // App Emblem in a highly structured Card frame mimicking Figma
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.12),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.health_and_safety_outlined, 
                        size: 40, 
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'Access Secure Health Ledger',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: AppColors.onBackground,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Unlock your credentials • Apnar Shastho, Apnar Hathe',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.outline,
                      fontSize: 14,
                    ),
                  ),
                  
                  const SizedBox(height: 36),

                  // Interactive Form Inside Medical Card Shell to elevate design
                  MedicalCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REGISTERED EMAIL',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary.withOpacity(0.85),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'e.g. email@domain.com',
                            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.outlineVariant),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Email is required';
                            if (!_isValidEmail(val)) return 'Enter a valid email address';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        Text(
                          'SECURITY PASSWORD',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary.withOpacity(0.85),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'Enter account password',
                            prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.primary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: AppColors.outline,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.outlineVariant),
                            ),
                          ),
                          validator: (val) => val == null || val.length < 6 ? 'Password must be 6+ characters' : null,
                        ),
                        
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Forgot Password?', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  Consumer(
                    builder: (context, ref, child) {
                      final authState = ref.watch(authNotifierProvider);
                      final isLoading = authState.isLoading;

                      return ClinicalButton(
                        label: isLoading ? 'Authenticating...' : 'Login Securely',
                        onPressed: isLoading ? () {} : () async {
                          if (_formKey.currentState!.validate()) {
                            try {
                              await ref.read(authNotifierProvider.notifier).login(
                                _phoneController.text.trim(),
                                _passController.text,
                              );
                              if (mounted) {
                                context.go('/home');
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString().replaceAll('Exception: ', '')),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      );
                    }
                  ),
                  
                  if (localAuthState.isBiometricAvailable) ...[
                    const SizedBox(height: 12),
                    ClinicalButton(
                      label: localAuthState.availableBiometrics.contains(BiometricType.face)
                          ? 'Unlock with FaceID'
                          : 'Unlock with Fingerprint',
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppColors.primary,
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      icon: localAuthState.availableBiometrics.contains(BiometricType.face)
                          ? Icons.face_retouching_natural
                          : Icons.fingerprint,
                      onPressed: _triggerBiometricUnlock,
                    ),
                  ],

                  const SizedBox(height: 32),
                  
                  // Navigation footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(color: AppColors.outline, fontWeight: FontWeight.w500),
                      ),
                      TextButton(
                        onPressed: () => context.push('/signup'),
                        child: const Text('Create One', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
