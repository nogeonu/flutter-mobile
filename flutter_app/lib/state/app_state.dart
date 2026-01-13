import 'package:flutter/foundation.dart';

import '../models/patient_session.dart';

class AppState extends ChangeNotifier {
  AppState._();

  static final AppState instance = AppState._();

  PatientSession? _session;

  PatientSession? get session => _session;

  bool get isLoggedIn => _session != null;

  void updateSession(PatientSession? session) {
    _session = session;
    notifyListeners();
  }
}
