import Flutter
import UIKit
import Speech

@available(iOS 10.0, *)
public class SwiftSpeechRecognitionPlugin: NSObject, FlutterPlugin, SFSpeechRecognizerDelegate {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "speech_recognition", binaryMessenger: registrar.messenger())
    let instance = SwiftSpeechRecognitionPlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  private let speechRecognizerEn = SFSpeechRecognizer(locale: Locale(identifier: "en_US"))!
  private let speechRecognizerDe = SFSpeechRecognizer(locale: Locale(identifier: "de_DE"))!

  private var speechChannel: FlutterMethodChannel?

  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

  private var recognitionTask: SFSpeechRecognitionTask?

  private let audioEngine = AVAudioEngine()

  init(channel:FlutterMethodChannel){
    speechChannel = channel
    super.init()
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    //result("iOS " + UIDevice.current.systemVersion)
    switch (call.method) {
    case "speech.activate":
      self.activateRecognition(result: result)
    case "speech.listen":
      self.startRecognition(lang: call.arguments as! String, result: result)
    case "speech.cancel":
      self.cancelRecognition(result: result)
    case "speech.stop":
      self.stopRecognition(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func activateRecognition(result: @escaping FlutterResult) {
    speechRecognizerEn.delegate = self
    speechRecognizerDe.delegate = self

    SFSpeechRecognizer.requestAuthorization { authStatus in
      OperationQueue.main.addOperation {
        switch authStatus {
        case .authorized:
          result(true)
          self.speechChannel?.invokeMethod("speech.onCurrentLocale", arguments: "\(Locale.current.identifier)")

        case .denied:
          result(false)

        case .restricted:
          result(false)

        case .notDetermined:
          result(false)
        }
        print("SFSpeechRecognizer.requestAuthorization \(authStatus.rawValue)")
      }
    }
  }

  private func startRecognition(lang: String, result: FlutterResult) {
    print("startRecognition...")

    try! start(lang: lang)
    result(true)

    // if audioEngine.isRunning {
    //   audioEngine.stop()
    //   recognitionRequest?.endAudio()
    //   result(false)
    // } else {
    //   try! start(lang: lang)
    //   result(true)
    // }
  }

  private func cancelRecognition(result: FlutterResult) {
    if let recognitionTask = recognitionTask {
      recognitionTask.cancel()
      self.recognitionTask = nil
      result(true)
    }
    else {
      result(false)
    }
  }

  private func stopRecognition(result: FlutterResult) {
    if audioEngine.isRunning {
      audioEngine.stop()
      // audioEngine.inputNode.removeTap(onBus: 0)
      recognitionRequest?.endAudio()
      result(true)
    }
    else {
      result(false)
    }
  }

  private func start(lang: String) throws {

    // cancelRecognition(result: nil)

    // Cancel the previous task if it's running.
    recognitionTask?.cancel()
    self.recognitionTask = nil

    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    let inputNode = audioEngine.inputNode

    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
    recognitionRequest.shouldReportPartialResults = true

    // Keep speech recognition data on device
    if #available(iOS 13, *) {
        recognitionRequest.requiresOnDeviceRecognition = false
    }

    let speechRecognizer = getRecognizer(lang: lang)

    recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
      var isFinal = false

      if let result = result {
        print("Speech : \(result.bestTranscription.formattedString)")
        self.speechChannel?.invokeMethod("speech.onSpeech", arguments: result.bestTranscription.formattedString)
        isFinal = result.isFinal

        if error != nil || isFinal {
          self.speechChannel!.invokeMethod("speech.onRecognitionComplete", arguments: result.bestTranscription.formattedString)
        }
      }

      if error != nil || isFinal {
        // Stop recognizing speech if there is a problem.
        self.audioEngine.stop()
        inputNode.removeTap(onBus: 0)

        self.recognitionRequest = nil
        self.recognitionTask = nil
      }
    }

    let recognitionFormat = inputNode.outputFormat(forBus: 0)
    // inputNode.removeTap(onBus: 0)
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recognitionFormat) {
      (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
      self.recognitionRequest?.append(buffer)
    }

    audioEngine.prepare()
    // if #available(iOS 11, *) {
    //     audioEngine.isAutoShutdownEnabled = true
    // }
    try audioEngine.start()

    speechChannel!.invokeMethod("speech.onRecognitionStarted", arguments: nil)
  }

  private func getRecognizer(lang: String) -> Speech.SFSpeechRecognizer {
    switch (lang) {
      case "en_US":
        return speechRecognizerEn
      case "de_DE":
        return speechRecognizerDe
      default:
        return speechRecognizerEn
    }

  }

  public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
    speechChannel?.invokeMethod("speech.onSpeechAvailability", arguments: available)
  }
}

// Helper function inserted by Swift 4.2 migrator.
// fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
// 	return input.rawValue
// }
