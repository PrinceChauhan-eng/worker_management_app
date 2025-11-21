import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import '../utils/logger.dart';

class WhatsAppService {
  static final WhatsAppService _instance = WhatsAppService._internal();
  factory WhatsAppService() => _instance;
  WhatsAppService._internal();

  // Store OTPs temporarily (in production, use secure backend)
  final Map<String, String> _otpStore = {};
  final Map<String, DateTime> _otpExpiry = {};

  // Generate 6-digit OTP
  String generateOTP() {
    final random = Random();
    String otp = '';
    for (int i = 0; i < 6; i++) {
      otp += random.nextInt(10).toString();
    }
    return otp;
  }

  // Send OTP via WhatsApp
  Future<bool> sendOTP(String phoneNumber, BuildContext context) async {
    try {
      // Clean phone number
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      
      // Generate OTP
      String otp = generateOTP();
      
      // Store OTP with 5 minute expiry
      _otpStore[cleanPhone] = otp;
      _otpExpiry[cleanPhone] = DateTime.now().add(const Duration(minutes: 5));
      
      Logger.info('Generated OTP for $cleanPhone: $otp (Valid for 5 minutes)');
      
      // Format phone number for WhatsApp (add country code if not present)
      String whatsappPhone = cleanPhone;
      if (!cleanPhone.startsWith('91') && cleanPhone.length == 10) {
        whatsappPhone = '91$cleanPhone'; // Add India country code
      }
      
      // Create WhatsApp message with OTP
      String message = '''
🔐 Worker Management App - OTP Verification

Your One-Time Password (OTP) is: *$otp*

⏰ Valid for 5 minutes
🔒 Do not share this OTP with anyone

If you didn't request this, please ignore this message.
''';
      
      // Encode message for URL
      String encodedMessage = Uri.encodeComponent(message);
      
      // Create WhatsApp URL
      final Uri whatsappUrl = Uri.parse(
        'https://wa.me/$whatsappPhone?text=$encodedMessage'
      );
      
      // Try to launch WhatsApp
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(
          whatsappUrl,
          mode: LaunchMode.externalApplication,
        );
        
        // Show info dialog
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF25D366)),
                  SizedBox(width: 10),
                  Text('OTP Sent'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'An OTP has been generated and WhatsApp has been opened.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your OTP Code:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          otp,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '⏰ Valid for 5 minutes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Note: In production, you would receive this OTP via WhatsApp message. For testing, use the code shown above.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        
        return true;
      } else {
        Logger.warn('Could not launch WhatsApp');
        
        // Show OTP in dialog even if WhatsApp can't be launched
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('OTP Generated'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('WhatsApp could not be opened.'),
                  const SizedBox(height: 10),
                  const Text('Your OTP code is:'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      otp,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Valid for 5 minutes',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        
        return true;
      }
    } catch (e) {
      Logger.error('Error sending OTP: $e', e);
      return false;
    }
  }

  // Verify OTP
  bool verifyOTP(String phoneNumber, String enteredOTP) {
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Check if OTP exists
    if (!_otpStore.containsKey(cleanPhone)) {
      Logger.warn('No OTP found for $cleanPhone');
      return false;
    }
    
    // Check if OTP is expired
    if (_otpExpiry[cleanPhone]!.isBefore(DateTime.now())) {
      Logger.warn('OTP expired for $cleanPhone');
      _otpStore.remove(cleanPhone);
      _otpExpiry.remove(cleanPhone);
      return false;
    }
    
    // Verify OTP
    bool isValid = _otpStore[cleanPhone] == enteredOTP;
    
    if (isValid) {
      Logger.info('OTP verified successfully for $cleanPhone');
      // Remove OTP after successful verification
      _otpStore.remove(cleanPhone);
      _otpExpiry.remove(cleanPhone);
    } else {
      Logger.warn('Invalid OTP for $cleanPhone. Expected: ${_otpStore[cleanPhone]}, Got: $enteredOTP');
    }
    
    return isValid;
  }

  // Clear OTP for a phone number
  void clearOTP(String phoneNumber) {
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    _otpStore.remove(cleanPhone);
    _otpExpiry.remove(cleanPhone);
  }

  // Check if OTP exists and is valid
  bool hasValidOTP(String phoneNumber) {
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (!_otpStore.containsKey(cleanPhone)) {
      return false;
    }
    
    if (_otpExpiry[cleanPhone]!.isBefore(DateTime.now())) {
      _otpStore.remove(cleanPhone);
      _otpExpiry.remove(cleanPhone);
      return false;
    }
    
    return true;
  }
}
