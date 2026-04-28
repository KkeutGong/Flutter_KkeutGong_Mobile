import 'package:flutter/material.dart';
import 'package:kkeutgong_mobile/core/session/session.dart';
import 'package:kkeutgong_mobile/data/repositories/report/report_repository.dart';

class ReportViewModel extends ChangeNotifier {
  final ReportRepository _repository;
  final Session _session = Session();

  ReportViewModel({ReportRepository? repository})
      : _repository = repository ?? ReportRepository();

  ReportData? _data;
  bool _isLoading = false;
  String? _error;

  ReportData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadReport() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await _repository.getReport(_session.currentCertificateId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _data = null;
    await loadReport();
  }
}
