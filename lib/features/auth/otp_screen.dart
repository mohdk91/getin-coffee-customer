import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../location/location_permission_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());
  bool _verifying = false;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verify() async {
    if (_verifying) return;

    final code = _controllers.map((controller) => controller.text).join();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the complete 6-digit code.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _verifying = true);

    // Local demo: simulate verification. Production will verify the OTP with
    // the auth backend and can display offline/expired-code errors here.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _verifying = false);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPermissionScreen(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;
    final systemBottom = MediaQuery.viewPaddingOf(context).bottom;
    final gap = compact ? 4.0 : 8.0;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            compact ? 18 : 24,
            18,
            compact ? 18 : 24,
            systemBottom + 24,
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
            ),
            SizedBox(height: compact ? 18 : 28),
            Text(
              'Verify Your Number',
              style: TextStyle(
                color: AppColors.green,
                fontSize: compact ? 27 : 30,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit code sent to ${widget.phoneNumber}',
              style: const TextStyle(color: AppColors.muted),
            ),
            SizedBox(height: compact ? 30 : 44),
            Row(
              children: List.generate(6, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 5 ? 0 : gap),
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _nodes[i],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      textInputAction:
                          i == 5 ? TextInputAction.done : TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      decoration: InputDecoration(
                        isDense: compact,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: compact ? 15 : 17,
                          horizontal: 2,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && i < 5) {
                          _nodes[i + 1].requestFocus();
                        } else if (value.isEmpty && i > 0) {
                          _nodes[i - 1].requestFocus();
                        }
                      },
                      onSubmitted: (_) {
                        if (i == 5) _verify();
                      },
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _verifying ? null : _verify,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.beige,
                ),
                child: _verifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.beige,
                        ),
                      )
                    : const Text('Verify & Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
