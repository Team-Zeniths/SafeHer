import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../models/contact_model.dart';

enum ContactsStatus { idle, loading, loaded, error }

/// Manages trusted contacts state — backed by the real Django API.
///
/// GET /api/v1/accounts/contacts/       → loadContacts
/// POST /api/v1/accounts/contacts/      → addContact
/// PATCH /api/v1/accounts/contacts/{id}/ → updateContact
/// DELETE /api/v1/accounts/contacts/{id}/ → deleteContact
class ContactsProvider extends ChangeNotifier {
  ContactsStatus _status = ContactsStatus.idle;
  List<ContactModel> _contacts = [];
  String? _errorMessage;
  String _searchQuery = '';

  ContactsStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  List<ContactModel> get contacts {
    if (_searchQuery.isEmpty) return _contacts;
    final q = _searchQuery.toLowerCase();
    return _contacts.where((c) {
      return c.name.toLowerCase().contains(q) || c.phone.contains(q);
    }).toList();
  }

  bool get isEmpty => _contacts.isEmpty;

  Future<void> loadContacts() async {
    if (_status == ContactsStatus.loading) return;
    _status = ContactsStatus.loading;
    notifyListeners();
    try {
      final response = await ApiService.instance.get('accounts/contacts/');
      final data = response.data as Map<String, dynamic>;
      // DRF paginated response: { count, results: [...] }
      final results = (data['results'] as List<dynamic>?) ?? [];
      _contacts = results.map((j) => ContactModel.fromJson(j as Map<String, dynamic>)).toList();
      _status = ContactsStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = ContactsStatus.error;
    }
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<bool> addContact(ContactModel contact) async {
    try {
      final response = await ApiService.instance.post(
        'accounts/contacts/',
        data: {
          'name': contact.name,
          'phone': contact.phone,
          'relationship': contact.relationship ?? '',
        },
      );
      final created = ContactModel.fromJson(response.data as Map<String, dynamic>);
      _contacts.add(created);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateContact(ContactModel contact) async {
    try {
      final response = await ApiService.instance.put(
        'accounts/contacts/${contact.id}/',
        data: {
          'name': contact.name,
          'phone': contact.phone,
          'relationship': contact.relationship ?? '',
        },
      );
      final updated = ContactModel.fromJson(response.data as Map<String, dynamic>);
      final idx = _contacts.indexWhere((c) => c.id == contact.id);
      if (idx != -1) {
        _contacts[idx] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteContact(String id) async {
    try {
      await ApiService.instance.delete('accounts/contacts/$id/');
      _contacts.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
