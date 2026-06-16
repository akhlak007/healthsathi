import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/firebase_auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _passController = TextEditingController();
  bool _acceptTerms = false;
  bool _obscurePassword = true;

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Actions: Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF006C4B).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.health_and_safety,
                                  size: 18, color: Color(0xFF006C4B)),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'HealthSathi',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF006C4B),
                                fontSize: 16,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Illustration
                    _buildIllustration(),

                    const SizedBox(height: 12),

                    // Title and Description
                    const Text(
                      'Join HealthSathi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Apnar Shastho, Apnar Hathe. Create an account to manage your medical records.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Full Name Form Field
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Full Name',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        filled: true,
                        //
                        fillColor: const Color(0xFFF8FAFC),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF006C4B), width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.error),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                        ),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Full name is required' : null,
                    ),

                    const SizedBox(height: 12),

                    // Phone or Email Form Field
                    TextFormField(
                      controller: _contactController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Phone or Email',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF006C4B), width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.error),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Email is required';
                        if (!_isValidEmail(val)) return 'Enter a valid email address';
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Password Form Field
                    TextFormField(
                      controller: _passController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Create Password',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: const Color(0xFF64748B),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF006C4B), width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.error),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                        ),
                      ),
                      validator: (val) => val == null || val.length < 6 ? 'Password must be 6+ characters' : null,
                    ),

                    const SizedBox(height: 12),

                    // Terms and Conditions
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _acceptTerms,
                            onChanged: (val) => setState(() => _acceptTerms = val ?? false),
                            activeColor: const Color(0xFF006C4B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            side: const BorderSide(color: Color(0xFF94A3B8)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'I agree to the Terms of Service & Privacy Protection Protocols',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Secure Register Button
                    Consumer(
                      builder: (context, ref, child) {
                        // Listen for signup completion and navigate
                        ref.listen(authNotifierProvider, (previous, next) {
                          if (mounted && next.hasValue && previous?.isLoading == true) {
                            context.push('/profile-setup');
                          }
                        });

                        final authState = ref.watch(authNotifierProvider);
                        final isLoading = authState.isLoading;

                        return ElevatedButton(
                          onPressed: isLoading ? () {} : () {
                            if (_formKey.currentState!.validate()) {
                              if (!_acceptTerms) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please accept the Terms of Service to proceed.'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }

                              ref.read(authNotifierProvider.notifier).signUp(
                                _contactController.text.trim(),
                                _passController.text,
                                _nameController.text.trim(),
                              ).catchError((e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString().replaceAll('Exception: ', '')),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006C4B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLoading ? 'Creating Account...' : 'Register & Continue',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (!isLoading) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 18),
                              ]
                            ],
                          ),
                        );
                      }
                    ),

                    const SizedBox(height: 20),

                    // Footer Link: Already registered? Log In
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already registered? ',
                          style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF006C4B),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return SizedBox(
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cloud backdrop
          Positioned(
            bottom: 10,
            child: Icon(
              Icons.cloud_queue_rounded,
              size: 110,
              color: const Color(0xFF10B981).withOpacity(0.15),
            ),
          ),
          // User profile icon
          Positioned(
            bottom: 5,
            left: 55,
            child: Transform.rotate(
              angle: -0.1,
              child: Icon(
                Icons.person_add_alt_1_rounded,
                size: 70,
                color: const Color(0xFF10B981).withOpacity(0.4),
              ),
            ),
          ),
          // Badge
          Positioned(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF006C4B).withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: const Icon(
                Icons.how_to_reg_rounded,
                size: 60,
                color: Color(0xFF059669),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
