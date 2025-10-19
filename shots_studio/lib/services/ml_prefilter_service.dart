
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'ml_prefilter_interface.dart';
import 'ml_prefilter_service_mobile.dart' if (dart.library.html) 'ml_prefilter_service_web.dart';

// Factory function to get the service
MLPrefilterService getMLPrefilterService() {
  return MLPrefilterServiceMobile();
}
