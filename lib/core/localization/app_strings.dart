import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_locale_provider.dart';

class AppStrings {
  static const Map<String, Map<String, String>> _values = {
    'settings': {'en': 'Settings', 'ur': 'ترتیبات'},
    'appearance': {'en': 'Appearance', 'ur': 'ظاہری شکل'},
    'dark_mode': {'en': 'Dark mode', 'ur': 'ڈارک موڈ'},
    'dark_mode_subtitle': {
      'en': 'Applies on next app restart',
      'ur': 'اگلی بار ایپ کھولنے پر لاگو ہوگا'
    },
    'notification_preferences': {
      'en': 'Notification preferences',
      'ur': 'اطلاعات کی ترجیحات'
    },
    'emergency_alerts': {'en': 'Emergency alerts', 'ur': 'ہنگامی الرٹس'},
    'emergency_alerts_subtitle': {
      'en': 'Nearby urgent blood requests',
      'ur': 'قریبی فوری خون کی درخواستیں'
    },
    'request_updates': {'en': 'Request updates', 'ur': 'درخواست کی تازہ کاری'},
    'request_updates_subtitle': {
      'en': 'When your request is accepted or fulfilled',
      'ur': 'جب آپ کی درخواست قبول یا مکمل ہو جائے'
    },
    'donation_reminders': {'en': 'Donation reminders', 'ur': 'عطیہ کی یاد دہانی'},
    'donation_reminders_subtitle': {
      'en': 'Reminders when you become eligible again',
      'ur': 'دوبارہ اہل ہونے پر یاد دہانی'
    },
    'privacy': {'en': 'Privacy', 'ur': 'رازداری'},
    'share_location': {
      'en': 'Share my location with requesters',
      'ur': 'میری لوکیشن درخواست دہندگان کے ساتھ شیئر کریں'
    },
    'share_location_subtitle': {
      'en': 'Needed to show distance in nearby search',
      'ur': 'قریبی تلاش میں فاصلہ دکھانے کے لیے ضروری'
    },
    'account': {'en': 'Account', 'ur': 'اکاؤنٹ'},
    'language': {'en': 'Language', 'ur': 'زبان'},
    'delete_account': {'en': 'Delete account', 'ur': 'اکاؤنٹ حذف کریں'},
    'delete_account_subtitle': {
      'en': 'Permanently remove your account',
      'ur': 'اپنا اکاؤنٹ مستقل طور پر حذف کریں'
    },
    'select_language': {'en': 'Select language', 'ur': 'زبان منتخب کریں'},
    'english': {'en': 'English', 'ur': 'انگریزی'},
    'urdu': {'en': 'Urdu', 'ur': 'اردو'},

    // Login
    'welcome_back': {'en': 'Welcome back', 'ur': 'خوش آمدید'},
    'login_subtitle': {
      'en': 'Log in to continue saving lives',
      'ur': 'زندگیاں بچانا جاری رکھنے کے لیے لاگ ان کریں'
    },
    'email': {'en': 'Email', 'ur': 'ای میل'},
    'password': {'en': 'Password', 'ur': 'پاس ورڈ'},
    'forgot_password': {'en': 'Forgot password?', 'ur': 'پاس ورڈ بھول گئے؟'},
    'log_in': {'en': 'Log In', 'ur': 'لاگ ان'},
    'no_account': {'en': 'Don\'t have an account?', 'ur': 'اکاؤنٹ نہیں ہے؟'},
    'sign_up': {'en': 'Sign up', 'ur': 'سائن اپ'},

    // Register
    'create_account': {'en': 'Create account', 'ur': 'اکاؤنٹ بنائیں'},
    'join_network': {'en': 'Join Smart Blood Network', 'ur': 'اسمارٹ بلڈ نیٹ ورک میں شامل ہوں'},
    'register_subtitle': {
      'en': 'Your details help save lives faster',
      'ur': 'آپ کی تفصیلات زندگیاں تیزی سے بچانے میں مدد کرتی ہیں'
    },
    'registering_as': {'en': 'I am registering as a:', 'ur': 'میں رجسٹر ہو رہا ہوں بطور:'},
    'donor': {'en': 'Donor', 'ur': 'عطیہ دہندہ'},
    'requester': {'en': 'Requester', 'ur': 'درخواست گزار'},
    'admin': {'en': 'Admin', 'ur': 'ایڈمن'},
    'full_name': {'en': 'Full name', 'ur': 'پورا نام'},
    'confirm_password': {'en': 'Confirm password', 'ur': 'پاس ورڈ کی تصدیق کریں'},

    // Dashboard
    'donor_dashboard': {'en': 'Donor dashboard', 'ur': 'عطیہ دہندہ ڈیش بورڈ'},
    'requester_dashboard': {'en': 'Requester dashboard', 'ur': 'درخواست گزار ڈیش بورڈ'},
    'admin_dashboard': {'en': 'Admin dashboard', 'ur': 'ایڈمن ڈیش بورڈ'},
    'hello': {'en': 'Hello', 'ur': 'ہیلو'},
    'available_to_donate': {'en': 'Available to donate', 'ur': 'عطیہ کرنے کے لیے دستیاب'},
    'quick_actions': {'en': 'Quick actions', 'ur': 'فوری اقدامات'},
    'active_emergencies': {'en': 'Active emergencies', 'ur': 'فعال ہنگامی صورتحال'},
  };

  static String get(BuildContext context, String key) {
    final locale = Provider.of<AppLocaleProvider>(context).locale;
    return _values[key]?[locale.languageCode] ?? _values[key]?['en'] ?? key;
  }
}