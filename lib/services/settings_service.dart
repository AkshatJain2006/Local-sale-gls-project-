import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const _kName = 'biz_name';
  static const _kAddress = 'biz_address';
  static const _kPhone = 'biz_phone';
  static const _kEmail = 'biz_email';
  static const _kGstin = 'biz_gstin';
  static const _kFooter = 'biz_footer';

  String businessName = 'LOCAL SALE STORE';
  String businessAddress = '';
  String businessPhone = '';
  String businessEmail = '';
  String gstin = '';
  String receiptFooter = 'Thank you for shopping with us!';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    businessName = prefs.getString(_kName) ?? 'LOCAL SALE STORE';
    businessAddress = prefs.getString(_kAddress) ?? '';
    businessPhone = prefs.getString(_kPhone) ?? '';
    businessEmail = prefs.getString(_kEmail) ?? '';
    gstin = prefs.getString(_kGstin) ?? '';
    receiptFooter = prefs.getString(_kFooter) ?? 'Thank you for shopping with us!';
    notifyListeners();
  }

  Future<void> save({
    required String name,
    required String address,
    required String phone,
    required String email,
    required String gstin,
    required String footer,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, name.trim().isEmpty ? 'LOCAL SALE STORE' : name.trim());
    await prefs.setString(_kAddress, address.trim());
    await prefs.setString(_kPhone, phone.trim());
    await prefs.setString(_kEmail, email.trim());
    await prefs.setString(_kGstin, gstin.trim());
    await prefs.setString(_kFooter, footer.trim().isEmpty ? 'Thank you for shopping with us!' : footer.trim());

    businessName = name.trim().isEmpty ? 'LOCAL SALE STORE' : name.trim();
    businessAddress = address.trim();
    businessPhone = phone.trim();
    businessEmail = email.trim();
    this.gstin = gstin.trim();
    receiptFooter = footer.trim().isEmpty ? 'Thank you for shopping with us!' : footer.trim();
    notifyListeners();
  }
}
