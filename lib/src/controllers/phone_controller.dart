import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phone_form_field/src/number_parser/models/phone_number.dart';

class PhoneController extends ValueNotifier<PhoneNumber?> {
  final PhoneNumber? initialValue;
  // when we want to select the national number
  final StreamController<void> _selectionRequestController =
      StreamController.broadcast();
  Stream<void> get selectionRequestStream => _selectionRequestController.stream;

  PhoneController(this.initialValue) : super(initialValue);

  selectNationalNumber() {
    _selectionRequestController.add(null);
  }

  reset() {
    value = null;
  }

  @override
  void dispose() {
    _selectionRequestController.close();
    super.dispose();
  }
}
