
import 'package:flutter/services.dart';

class AudioEngine {
  static const MethodChannel _channel =
      MethodChannel('com.idrish.shairerasool/audio');

  Future<bool> start() async {
    try {
      return await _channel.invokeMethod<bool>('start') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> stop() async {
    await _channel.invokeMethod<void>('stop');
  }

  Future<void> setDelay(int milliseconds) async {
    await _channel.invokeMethod<void>(
      'setDelay',
      {'milliseconds': milliseconds},
    );
  }

  Future<void> setFeedback(double value) async {
    await _channel.invokeMethod<void>(
      'setFeedback',
      {'value': value},
    );
  }

  Future<void> setEffectLevel(double value) async {
    await _channel.invokeMethod<void>(
      'setEffectLevel',
      {'value': value},
    );
  }
}
