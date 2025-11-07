import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wisdomwalk/providers/auth_provider.dart';
import 'package:wisdomwalk/widgets/loading_overlay.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({Key? key, required this.email})
    : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _submitOtp() {
    if (_formKey.currentState!.validate()) {
      // Skip server-side OTP verification and navigate directly to ResetPasswordScreen
      debugPrint(
        'Submitting OTP: email=${widget.email}, otp=${_otpController.text.trim()}',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proceeding to reset password'),
          backgroundColor: Color(0xFF4A4A4A),
        ),
      );
      context.go(
        '/reset-password',
        extra: {'email': widget.email, 'otp': _otpController.text.trim()},
      );
    }
  }

  Future<void> _resendOtp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resendOtp(email: widget.email);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New OTP sent to your email'),
          backgroundColor: Color(0xFF4A4A4A),
        ),
      );
    } else if (mounted && authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return LoadingOverlay(
      isLoading: authProvider.isLoading,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            "Verify OTP",
            style: TextStyle(color: Color(0xFF757575)),
          ),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF757575)),
            onPressed: () => context.go('/forgot-password'),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Icon(
                  Icons.email_outlined,
                  size: 70,
                  color: Color(0xFFD4A017),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4A4A),
                    fontFamily: 'Playfair Display',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter the 6-digit code sent to ${widget.email}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF757575),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                _buildOtpForm(),
                const SizedBox(height: 20),
                _buildResendOtpLink(),
                const SizedBox(height: 40),
                _buildVerifyButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpForm() {
    return Form(
      key: _formKey,
      child: TextFormField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        decoration: InputDecoration(
          labelText: 'Verification Code',
          hintText: 'Enter 6-digit code',
          prefixIcon: const Icon(Icons.vpn_key, color: Color(0xFFD4A017)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE8E2DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE8E2DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD4A017)),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter the verification code';
          }
          if (value.length != 6 || !RegExp(r'^\d{6}$').hasMatch(value)) {
            return 'Please enter a valid 6-digit code';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildResendOtpLink() {
    return TextButton(
      onPressed: _resendOtp,
      child: const Text(
        'Resend OTP',
        style: TextStyle(color: Color(0xFFD4A017), fontSize: 14),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _submitOtp, // Updated to _submitOtp
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4A017),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Verify OTP',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
