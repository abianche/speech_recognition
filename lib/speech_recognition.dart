import 'dart:async';

import 'dart:ui';
import 'package:flutter/services.dart';

import 'package:speech_recognition/speech_enum.dart';
export 'package:speech_recognition/speech_enum.dart';

typedef void AvailabilityHandler(bool result);
typedef void StringResultHandler(String text);
typedef void ErrorHandler(SpeechRecognitionError error);

/// the channel to control the speech recognition
class SpeechRecognition {
  static const MethodChannel _channel =
      const MethodChannel('speech_recognition');

  static final SpeechRecognition _speech = new SpeechRecognition._internal();

  factory SpeechRecognition() => _speech;

  SpeechRecognition._internal() {
    _channel.setMethodCallHandler(_platformCallHandler);
  }

  AvailabilityHandler availabilityHandler;

  StringResultHandler currentLocaleHandler;
  StringResultHandler recognitionResultHandler;

  VoidCallback recognitionStartedHandler;

  StringResultHandler recognitionCompleteHandler;

  ErrorHandler errorHandler;

  /// ask for speech  recognizer permission
  Future<bool> activate() => _channel.invokeMethod("speech.activate");

  /// start listening
  Future<bool> listen({String locale}) =>
      _channel.invokeMethod("speech.listen", locale);

  /// cancel speech
  Future<bool> cancel() => _channel.invokeMethod("speech.cancel");

  /// stop listening
  Future<bool> stop() => _channel.invokeMethod("speech.stop");

  Future _platformCallHandler(MethodCall call) async {
    print("Method channel [${call.method}]");
    if (call.arguments != null) print("with arguments [${call.arguments}]");

    switch (call.method) {
      case "speech.onSpeechAvailability":
        availabilityHandler(call.arguments);
        break;
      case "speech.onCurrentLocale":
        currentLocaleHandler(call.arguments);
        break;
      case "speech.onSpeech":
        recognitionResultHandler(call.arguments);
        break;
      case "speech.onRecognitionStarted":
        recognitionStartedHandler();
        break;
      case "speech.onRecognitionComplete":
        recognitionCompleteHandler(call.arguments);
        break;
      case "speech.onError":
        errorHandler(SpeechRecognitionError.fromInt(call.arguments));
        break;
      default:
        print('Unknowm method ${call.method} ');
    }
  }

  // define a method to handle availability / permission result
  void setAvailabilityHandler(AvailabilityHandler handler) =>
      availabilityHandler = handler;

  // define a method to handle recognition result
  void setRecognitionResultHandler(StringResultHandler handler) =>
      recognitionResultHandler = handler;

  // define a method to handle native call
  void setRecognitionStartedHandler(VoidCallback handler) =>
      recognitionStartedHandler = handler;

  // define a method to handle native call
  void setRecognitionCompleteHandler(StringResultHandler handler) =>
      recognitionCompleteHandler = handler;

  void setCurrentLocaleHandler(StringResultHandler handler) =>
      currentLocaleHandler = handler;

  void setErrorHandler(ErrorHandler handler) => errorHandler = handler;
}
