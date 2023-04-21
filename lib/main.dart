// ignore_for_file: unnecessary_null_comparison

import 'dart:io';

import 'package:easy_audio_trimmer/easy_audio_trimmer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:interlude/utils/label.dart';
import 'package:interlude/utils/type_utils.dart';
import 'package:interlude/utils/button.dart';
import 'package:interlude/widget_utils/bottom_view.dart';
import 'package:interlude/widget_utils/chat_bubble_view.dart';
import 'package:interlude/widget_utils/dropdown_view.dart';
import 'package:interlude/widget_utils/tab_view.dart';
import 'package:path_provider/path_provider.dart';
import 'widget_utils/header_view.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const Interlude());
}

class Interlude extends StatelessWidget {
  const Interlude({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  // Initializing a global key, as it would help us in showing a SnackBar later
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  //Define variables, which will be required for audio trimmer
  File? file;
  final Trimmer _trimmer = Trimmer();
  double startValue = 0.0;
  double endValue = 0.0;
  bool isPlaying = false;
  bool playbackState = false;
  bool isLoading = false;

  //Define label variables
  String fileName = "NA";
  Duration duration = const Duration();

  // Get the instance of the bluetooth
  FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;

  // Define some variables, which will be required later
  List<BluetoothDevice> devicesList = [];
  BluetoothDevice? device;
  String? selectedValue;
  bool connected = false;

  //Recording variables
  String? path;
  bool isRecording = false;
  bool isRecordingCompleted = false;
  Directory? appDirectory;
  late final RecorderController recorderController;
  File? savingFile;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    getDir();
    _initialiseControllers();
    bluetoothConnectionState();
  }

  // We are using async callback for using await
  Future<void> bluetoothConnectionState() async {
    List<BluetoothDevice> devices = [];

    // To get the list of paired devices
    try {
      devices = await bluetooth.getBondedDevices();
    } on PlatformException {
      debugPrint("Error");
    }

    // It is an error to call [setState] unless [mounted] is true.
    if (!mounted) {
      return;
    }

    // Store the [devices] list in the [_devicesList] for accessing
    // the list outside this class
    setState(() {
      devicesList = devices;
    });
  }

  //Load audio file to trimmer controller
  void _loadAudio() async {
    if (file != null) {
      await _trimmer.loadAudio(audioFile: file!);
      if (mounted) {
        setState(() {
          fileName = file!.path;
          isLoading = true;
        });
      }
      _getDuration(fileName);
    }
  }

  void getDir() async {
    final statusStorage = await Permission.storage.status;
    if (!statusStorage.isGranted) {
      await Permission.storage.request();
    }
    appDirectory = (await getExternalStorageDirectory())!;
    path = "${appDirectory!.path}/SavedRecording.m4a";
    setState(() {});
  }

  void _getDuration(String filePath) async {
    final player = AudioPlayer();
    var durational = await player.setFilePath(filePath);
    setState(() {
      duration = durational!;
    });
  }

  void _initialiseControllers() {
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 96000;
  }

  void startOrStopRecording() async {
    try {
      if (file == null) {
        debugPrint("Please select background audio");
        return;
      }

      if (isRecording) {
        recorderController.reset();
        final path = await recorderController.stop(false);

        if (path != null) {
          isRecordingCompleted = true;
          debugPrint(path);
          debugPrint("Recorded file size: ${File(path).lengthSync()}");
        }
      } else {
        appDirectory = (await getExternalStorageDirectory())!;
        path = "${appDirectory!.path}/SavedRecording.m4a";
        if (path != null) {
          File file = File(path!);
          if (file.existsSync()) {
            await file.delete();
            savingFile == null;
            isRecordingCompleted = false;
          }
        }

        if (_trimmer.audioPlayer != null) {
          playbackState = await _trimmer.audioPlaybackControl(
            startValue: startValue,
            endValue: endValue,
          );
          await _trimmer.audioPlayer!.resume();
        }
        await recorderController.record(path: path!);
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (file != null) {
        if (isRecording) {
          playbackState = false;
          isPlaying = false;
          if (_trimmer.audioPlayer != null) {
            playbackState = await _trimmer.audioPlaybackControl(
              startValue: startValue,
              endValue: endValue,
            );
            await _trimmer.audioPlayer!.pause();
          }

          isRecording = !isRecording;

          savingFile = File(path!);
          // _loadSavedAudio();

          setState(() {});
        } else {
          setState(() {
            isRecording = !isRecording;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (mounted) {
      _trimmer.dispose();
    }
    recorderController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var sWidth = MediaQuery.of(context).size.width;
    var sHeight = MediaQuery.of(context).size.height;
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).userGestureInProgress) {
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: Container(
          padding: const EdgeInsets.fromLTRB(30, 10, 30, 0),
          height: sHeight,
          width: sWidth,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              const HeaderView(),
              TabViewCustom(tabController: tabController),
              //TabBarView
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    //first tab bar view
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child:
                              PathLabel(fileName: fileName, duration: duration),
                        ),

                        //LoadingFileView
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            file == null
                                ? Button(
                                    label: "Select sound",
                                    color: Colors.white,
                                    buttonStyle: TypeClass.srButtonStyle,
                                    onPressFunc: filePickFunc)
                                : Padding(
                                    padding: const EdgeInsets.all(0.0),
                                    child: TrimViewer(
                                      trimmer: _trimmer,
                                      viewerHeight: 50,
                                      viewerWidth: sWidth - 60,
                                      maxAudioLength:
                                          const Duration(minutes: 50),
                                      durationStyle: DurationStyle.FORMAT_MM_SS,
                                      backgroundColor: const Color(0x1A0075F8),
                                      barColor: const Color(0xFFFFFFFF),
                                      durationTextStyle: const TextStyle(
                                          color: Color(0xFFFFFFFF)),
                                      allowAudioSelection: true,
                                      editorProperties:
                                          const TrimEditorProperties(
                                        circleSize: 5,
                                        borderPaintColor: Color(0xFFc80000),
                                        borderWidth: 1,
                                        borderRadius: 0,
                                        circlePaintColor: Color(0xFFc80000),
                                        scrubberWidth: 3,
                                        scrubberPaintColor: Color(0xFFc80000),
                                      ),
                                      areaProperties:
                                          TrimAreaProperties.edgeBlur(
                                              blurEdges: true),
                                      onChangeStart: (value) =>
                                          startValue = value,
                                      onChangeEnd: (value) => endValue = value,
                                      onChangePlaybackState: (value) {
                                        if (mounted) {
                                          setState(() => isPlaying = value);
                                        }
                                      },
                                    ),
                                  ),
                          ],
                        ),

                        //DropDownView
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Sound Output:",
                                style: TypeClass.bodyTextStyle,
                              ),
                              DropDownView(
                                hint: "Select output",
                                value: selectedValue,
                                dropdownItems: getDeviceItems(),
                                onChanged: (value) {
                                  selectFunction(value);
                                },
                                hintAlignment: Alignment.centerRight,
                                valueAlignment: Alignment.centerRight,
                              ),
                            ],
                          ),
                        ),

                        //Bluetooth Connection Title
                        Container(
                          padding: const EdgeInsets.only(top: 10),
                          alignment: Alignment.centerLeft,
                          child: connected
                              ? Row(children: [
                                  const Icon(
                                    Icons.circle,
                                    color: Colors.green,
                                  ),
                                  Text(
                                    "Bluetooth Connected",
                                    style: TypeClass.bodyTextStyle,
                                  )
                                ])
                              : Text(
                                  "Change output to to Bluetooth device to start recording",
                                  style: TypeClass.bodyTextStyle,
                                  textAlign: TextAlign.left,
                                ),
                        ),
                        Expanded(
                          child: !isRecording && isLoading
                              ? Container(
                                  alignment: Alignment.bottomCenter,
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    "Select your audio selection above and start recording",
                                    style: TypeClass.bodyTextStyle,
                                  ),
                                )
                              : Container(),
                        ),

                        //Recording Button
                        Container(
                          width: sWidth,
                          alignment: Alignment.bottomCenter,
                          padding: EdgeInsets.zero,
                          child: IconButton(
                            onPressed: () {
                              startOrStopRecording();
                            },
                            icon: Icon(isRecording ? Icons.stop : Icons.mic),
                            color: Colors.red,
                            iconSize: 50,
                          ),
                        ),
                        //Bubble View
                        isRecordingCompleted && savingFile != null
                            ? Expanded(
                                child: Container(
                                  color: Colors.transparent,
                                  child: Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    // child: TrimViewer(
                                    //   trimmer: _trimmerSave,
                                    //   viewerHeight: 80,
                                    //   maxAudioLength: const Duration(minutes: 50),
                                    //   durationStyle: DurationStyle.FORMAT_MM_SS,
                                    //   backgroundColor: ColorUtils.appColorAccent_10,
                                    //   barColor: ColorUtils.appColorWhite,
                                    //   durationTextStyle: TextStyle(color: ColorUtils.appColorWhite),
                                    //   allowAudioSelection: true,
                                    //   editorProperties: TrimEditorProperties(
                                    //     circleSize: 5,
                                    //     borderPaintColor: ColorUtils.appColorBlue,
                                    //     borderWidth: 1,
                                    //     borderRadius: 0,
                                    //     circlePaintColor: ColorUtils.appColorBlue,
                                    //     scrubberWidth: 3,
                                    //     scrubberPaintColor: ColorUtils.appColorBlue,
                                    //   ),
                                    //   areaProperties: TrimAreaProperties.edgeBlur(blurEdges: true),
                                    //   onChangeStart: (value) => _startValueSave = value,
                                    //   onChangeEnd: (value) => _endValueSave = value,
                                    //   onChangePlaybackState: (value) {
                                    //     if (mounted) {
                                    //       setState(() => _isPlayingSave = value);
                                    //     }
                                    //   },
                                    // ),
                                    child: WaveBubble(
                                      path: path,
                                      isSender: true,
                                      appDirectory: appDirectory!,
                                    ),
                                  ),
                                ),
                              )
                            : Container(),
                        const BottomView(),
                      ],
                    ),
                    //second tab bar view
                    Container(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void filePickFunc() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowCompression: false,
    );
    if (result != null) {
      file = File(result.files.single.path!);
      _loadAudio();
    }
  }

  List<String> getDeviceItems() {
    List<String> dropdownItems = ["Speaker"];
    if (devicesList.isEmpty) {
      // dropdownItems.add("Speaker");
      debugPrint("No Devices found");
    } else {
      for (var device in devicesList) {
        dropdownItems.add(device.name!);
      }
    }
    return dropdownItems;
  }

// Method to connect to bluetooth
  void connect() {
    if (device == null) {
    } else {
      bluetooth.isConnected.then((isEnabled) {
        if (!isEnabled) {
          bluetooth
              .connect(device!)
              .timeout(const Duration(seconds: 10))
              .catchError((error) {
            debugPrint(error);
          });
        }
      });
    }
  }

  // Method to disconnect bluetooth
  void disconnect() {
    bluetooth;
  }

  void selectFunction(String? value) {
    if (device != null) {
      disconnect();
      device = null;
    }
    for (var selectedDevice in devicesList) {
      if (selectedDevice.name == value) {
        device = selectedDevice;
      }
    }
    connect();
    setState(() {
      selectedValue = value;
      if (device == null) {
        connected = false;
      } else {
        connected = true;
      }
    });
  }
}
