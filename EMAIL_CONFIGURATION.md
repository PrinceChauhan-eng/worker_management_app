# 📧 Email Service Configuration Guide

## 📋 Overview
This guide explains how to configure the real email service for production deployment of the Worker Management App.

## 🛠️ Configuration Options

### Option 1: Environment Variables (Recommended)
Set these environment variables when running the app:

```bash
# Gmail SMTP Configuration (Example)
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SENDER_EMAIL=your-email@gmail.com
SENDER_NAME="Worker Management App"
```

### Option 2: Direct Code Configuration
Modify the constants in `lib/services/email_verification_service.dart`:

```dart
const String _smtpUsername = 'your-email@gmail.com';
const String _smtpPassword = 'your-app-password';
const String _senderEmail = 'your-email@gmail.com';
const String _senderName = 'Worker Management App';
```

## 📧 Supported Email Providers

### Gmail (Recommended for Testing)
1. Enable 2-Factor Authentication on your Gmail account
2. Generate an App Password:
   - Go to Google Account settings
   - Security → 2-Step Verification → App passwords
   - Generate a new app password for "Mail"
3. Use the app password as `_smtpPassword`

### Other Providers
The app supports any SMTP server. Common configurations:

#### Outlook/Hotmail
```bash
SMTP_SERVER=smtp-mail.outlook.com
SMTP_PORT=587
```

#### Yahoo
```bash
SMTP_SERVER=smtp.mail.yahoo.com
SMTP_PORT=587
```

## 🚀 Deployment Instructions

### For Web Deployment
1. Set environment variables in your hosting platform
2. Example for Firebase Hosting:
   ```bash
   firebase functions:config:set smtp.username="your-email@gmail.com" smtp.password="your-password"
   ```

### For Mobile Deployment
1. Add to your build process:
   ```bash
   flutter build apk --dart-define=SMTP_USERNAME=your-email@gmail.com --dart-define=SMTP_PASSWORD=your-app-password
   ```

## 🔧 Testing the Configuration

### Demo Mode (Default)
- No configuration required
- OTP shown directly to user
- Perfect for development/testing

### Production Mode
- Requires SMTP credentials
- Sends real emails
- Falls back to demo mode on failure

## 🛡️ Security Best Practices

1. **Never commit credentials** to version control
2. **Use App Passwords** for Gmail (not your regular password)
3. **Environment Variables** for production deployment
4. **Secure Storage** for mobile apps

## 📝 Email Template

The verification email uses this template:

```
Subject: Email Verification - Worker Management App

Hello,

Your verification code is: [6-DIGIT CODE]

Please enter this code in the application to verify your email address.

If you did not request this verification, please ignore this email.

Best regards,
Worker Management App Team
```

## 🆘 Troubleshooting

### Common Issues

1. **Email not sending:**
   - Check SMTP credentials
   - Verify network connectivity
   - Ensure firewall allows SMTP ports

2. **Authentication errors:**
   - Use App Passwords for Gmail
   - Check username/password
   - Verify 2FA is enabled

3. **Gmail specific:**
   - Less secure apps must be disabled
   - Use App Passwords instead of regular password

### Debugging
Enable verbose logging by checking the browser console or device logs for:
- "Sending real email via SMTP"
- "Email sent successfully"
- Error messages with details

## 🔄 Fallback Behavior

If email sending fails:
1. App shows OTP in notifications (toast + dialog)
2. User can still verify with the displayed code
3. No interruption to user experience

This ensures users can always verify their email even if the email service is temporarily unavailable.