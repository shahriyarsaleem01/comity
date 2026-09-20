import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _monthYear = DateFormat('MMM yyyy');
  static final DateFormat _fullDate = DateFormat('dd MMM yyyy');
  static final DateFormat _shortDate = DateFormat('dd/MM/yyyy');

  static String formatMonthYear(DateTime date) {
    return _monthYear.format(date);
  }

  static String formatFullDate(DateTime date) {
    return _fullDate.format(date);
  }

  static String formatShortDate(DateTime date) {
    return _shortDate.format(date);
  }

  static DateTime getMonthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime getMonthEnd(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  static int monthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + end.month - start.month;
  }

  static DateTime addMonths(DateTime date, int months) {
    return DateTime(date.year, date.month + months, date.day);
  }
}

class NumberUtils {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs. ',
    decimalDigits: 0,
  );

  static String formatCurrency(int amount) {
    return _currency.format(amount);
  }

  static String formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  static int parseAmount(String text) {
    return int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }
}

class PhoneUtils {
  static String formatPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith('+92')) {
      return cleaned;
    } else if (cleaned.startsWith('0')) {
      return '+92${cleaned.substring(1)}';
    } else if (cleaned.length == 10) {
      return '+92$cleaned';
    }
    return cleaned;
  }

  static String getDisplayPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('92') && cleaned.length == 12) {
      return '0${cleaned.substring(2)}';
    }
    return cleaned;
  }

  static bool isValidPakistanPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return RegExp(r'^(?:92|0)?3\d{9}$').hasMatch(cleaned);
  }
}

class ValidationUtils {
  static String? requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (!PhoneUtils.isValidPakistanPhone(value)) {
      return 'Enter a valid Pakistan phone number';
    }
    return null;
  }

  static String? amountValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final amount = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (amount == null || amount <= 0) {
      return 'Enter a valid amount';
    }
    return null;
  }

  static String? nameValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }
}

class CommitteeUtils {
  static String getStatusText(String status) {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return const Color(0xFF757575);
      case 'active':
        return const Color(0xFF2E7D32);
      case 'completed':
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFF757575);
    }
  }

  static String getRoleText(String role) {
    switch (role) {
      case 'organizer':
        return 'Organizer';
      case 'member':
        return 'Member';
      default:
        return 'Member';
    }
  }
}