import 'package:flutter/material.dart';
import 'package:speech_recognition/speech_recognition.dart';

void main() {
  runApp(new MyApp());
}

const languages = const [
  const Language('English', 'en_US'),
  const Language('German', 'de_DE'),
];

class Language {
  final String name;
  final String code;

  const Language(this.name, this.code);
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  SpeechRecognition _speech;

  bool _speechRecognitionAvailable = false;
  bool _isListening = false;

  String transcription = '';

  //String _currentLocale = 'en_US';
  Language selectedLang = languages.first;

  @override
  initState() {
    super.initState();
    activateSpeechRecognizer();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  void activateSpeechRecognizer() {
    print('Activating recognition ...');
    _speech = new SpeechRecognition();
    _speech.setAvailabilityHandler(onSpeechAvailability);
    _speech.setCurrentLocaleHandler(onCurrentLocale);
    _speech.setRecognitionStartedHandler(onRecognitionStarted);
    _speech.setRecognitionResultHandler(onRecognitionResult);
    _speech.setRecognitionCompleteHandler(onRecognitionComplete);
    _speech.setErrorHandler(errorHandler);
    _speech.activate().then((activated) => setState(() {
          print('Activating recognition is $activated');
          _speechRecognitionAvailable = activated;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('SpeechRecognition (demo)'),
          backgroundColor: Colors.black,
          actions: [
            new PopupMenuButton<Language>(
              onSelected: _selectLangHandler,
              itemBuilder: (BuildContext context) => _buildLanguagesWidgets,
            )
          ],
        ),
        body: new Padding(
            padding: new EdgeInsets.all(8.0),
            child: new Center(
              child: new Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  new Expanded(
                      child: new Container(
                          padding: const EdgeInsets.all(8.0),
                          color: Colors.grey.shade200,
                          child: new Text(
                            transcription,
                            textScaleFactor: 4.0,
                          ))),
                  _buildButton(
                    onPressed: _speechRecognitionAvailable && !_isListening
                        ? () => start()
                        : null,
                    label: _isListening
                        ? 'Listening...'
                        : 'Listen (${selectedLang.code})',
                  ),
                  _buildButton(
                    onPressed: _isListening ? () => cancel() : null,
                    //onPressed: () => cancel(),
                    label: 'Cancel',
                  ),
                  _buildButton(
                    // onPressed: () => stop(),
                    onPressed: _isListening ? () => stop() : null,
                    label: 'Stop',
                  ),
                ],
              ),
            )),
      ),
    );
  }

  List<CheckedPopupMenuItem<Language>> get _buildLanguagesWidgets => languages
      .map((l) => new CheckedPopupMenuItem<Language>(
            value: l,
            checked: selectedLang == l,
            child: new Text(l.name),
          ))
      .toList();

  void _selectLangHandler(Language lang) {
    setState(() => selectedLang = lang);
  }

  Widget _buildButton({String label, VoidCallback onPressed}) => new Padding(
      padding: new EdgeInsets.all(12.0),
      child: new RaisedButton(
        color: Colors.black,
        onPressed: onPressed,
        child: new Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
      ));

  // void start() => _speech
  //     .listen(locale: selectedLang.code)
  //     .then((result) => print('_MyAppState.start => result $result'));

  // void start() => _speech.listen(locale: selectedLang.code).then(
  //     (startedSuccessfully) => print(
  //         'Start recognition with language ${selectedLang.code} is $startedSuccessfully'));

  void start() async {
    bool started = await _speech.listen(locale: selectedLang.code);
    print('Start recognition with language ${selectedLang.code} is $started');
  }

  void cancel() async {
    bool wasCancelled = await _speech.cancel();
    print("Was cancelled: $wasCancelled");
    setState(() => _isListening = false);
  }

  void stop() async {
    bool wasRunning = await _speech.stop();
    print("Was running: $wasRunning");
    setState(() => _isListening = false);
  }

  void onSpeechAvailability(bool result) {
    print("Speech available: $result");
    setState(() => _speechRecognitionAvailable = result);
  }

  void onCurrentLocale(String locale) {
    print('Authorized, with locale $locale');
    setState(
        () => selectedLang = languages.firstWhere((l) => l.code == locale));
  }

  void onRecognitionStarted() {
    print("Started");
    setState(() => _isListening = true);
  }

  void onRecognitionResult(String text) {
    print("Partial result: $text");
    setState(() => transcription = text);
  }

  void onRecognitionComplete(String text) {
    print("Final result: $text");
    setState(() => _isListening = false);
  }

  void errorHandler(SpeechRecognitionError error) {
    print("Error: ${error.toString()}");
    activateSpeechRecognizer();
  }
}
