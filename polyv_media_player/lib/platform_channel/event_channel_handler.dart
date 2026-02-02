import 'dart:async';

import 'package:flutter/services.dart';

class EventChannelHandler {
  static Stream<dynamic> receiveStream(EventChannel channel) {
    return channel.receiveBroadcastStream();
  }
}
