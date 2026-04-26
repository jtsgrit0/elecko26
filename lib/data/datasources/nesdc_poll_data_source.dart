export 'nesdc_poll_data_source_unsupported.dart'
    if (dart.library.io) 'nesdc_poll_data_source_mobile.dart'
    if (dart.library.html) 'nesdc_poll_data_source_web.dart';
