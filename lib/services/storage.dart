// Local storage of estimates (JSON in SharedPreferences, offline-first).

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/estimate.dart';

class EstimateStorage {
  static const String _estimatesKey = 'painteasy_estimates';

  Future<List<Estimate>> loadAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_estimatesKey);
    if (raw == null || raw.isEmpty) {
      return <Estimate>[];
    }
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final List<Estimate> estimates = decoded
          .map((dynamic e) => Estimate.fromJson(e as Map<String, dynamic>))
          .toList();
      // Newest first.
      estimates.sort((Estimate a, Estimate b) =>
          b.createdAt.compareTo(a.createdAt));
      return estimates;
    } catch (_) {
      return <Estimate>[];
    }
  }

  Future<void> _saveAll(List<Estimate> estimates) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = jsonEncode(
      estimates.map((Estimate e) => e.toJson()).toList(),
    );
    await prefs.setString(_estimatesKey, raw);
  }

  /// Insert a new estimate, or replace the one with the same id.
  Future<void> save(Estimate estimate) async {
    final List<Estimate> all = await loadAll();
    final int index = all.indexWhere((Estimate e) => e.id == estimate.id);
    if (index >= 0) {
      all[index] = estimate;
    } else {
      all.add(estimate);
    }
    await _saveAll(all);
  }

  /// Duplicate an estimate under a new id and a " (Copy)" title.
  Future<Estimate> duplicate(Estimate estimate) async {
    final Estimate copy = estimate.copyWith(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: '${estimate.title} (Copy)',
      createdAt: DateTime.now(),
    );
    await save(copy);
    return copy;
  }

  Future<void> delete(String id) async {
    final List<Estimate> all = await loadAll();
    all.removeWhere((Estimate e) => e.id == id);
    await _saveAll(all);
  }
}
