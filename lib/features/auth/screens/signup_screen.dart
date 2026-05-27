import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/clinical_widgets.dart';
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
  bool _isSubmitting = false;

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.person_add_outlined, size: 36, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Join HealthSathi',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Apnar Shastho, Apnar Hathe',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.outline,
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 32),

                // Form card
                MedicalCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FULL NAME',
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
                        controller: _nameController,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'John Doe',
                          prefixIcon: const Icon(Icons.person, color: AppColors.primary),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.outlineVariant),
                          ),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Full name is required' : null,
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'PHONE OR EMAIL',
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
                        controller: _contactController,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'email@domain.com',
                          prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                      const SizedBox(height: 16),

                      Text(
                        'CREATE PASSWORD',
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
                          hintText: 'Must be at least 6 characters',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.outline,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.outlineVariant),
                          ),
                        ),
                        validator: (val) => val == null || val.length < 6 ? 'Password must be 6+ characters' : null,
                      ),
                      
                      const SizedBox(height: 12),

                      CheckboxListTile(
                        value: _acceptTerms,
                        onChanged: (val) => setState(() => _acceptTerms = val ?? false),
                        title: Text(
                          'I agree to the Terms of Service & Privacy Protection Protocols',
                          style: textTheme.labelSmall?.copyWith(fontSize: 11),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                Consumer(
                  builder: (context, ref, child) {
                    // Listen for signup completion and navigate
                    ref.listen(authNotifierProvider, (previous, next) {
                      if (mounted && next.hasValue && previous?.isLoading == true) {
                        context.push('/profile-setup');
                      }
                    });

                    return ClinicalButton(
                      label: _isSubmitting ? 'Creating Account...' : 'Register & Continue',
                      onPressed: _isSubmitting ? () {} : () {
                        if (_formKey.currentState!.validate()) {
                          if (!_acceptTerms) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please accept the Terms of Service to proceed.')),
                            );
                            return;
                          }

                          setState(() => _isSubmitting = true);
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
                              setState(() => _isSubmitting = false);
                            }
                          });
                        }
                      },
                    );
                  }
                ),
                
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already registered?", style: TextStyle(color: AppColors.outline)),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
