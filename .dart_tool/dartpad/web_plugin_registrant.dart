// Flutter web plugin registrant file.
//
// Generated file. Do not edit.
//

// @dart = 2.13
// ignore_for_file: type=lint

import 'package:audio_session/audio_session_web.dart';
import 'package:audioplayers_web/audioplayers_web.dart';
import 'package:connectivity_plus/src/connectivity_plus_web.dart';
import 'package:file_picker/_internal/file_picker_web.dart';
import 'package:fluttertoast/fluttertoast_web.dart';
import 'package:just_audio_web/just_audio_web.dart';
import 'package:shared_preferences_web/shared_preferences_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void registerPlugins([final Registrar? pluginRegistrar]) {
  final Registrar registrar = pluginRegistrar ?? webPluginRegistrar;
  AudioSessionWeb.registerWith(registrar);
  AudioplayersPlugin.registerWith(registrar);
  ConnectivityPlusWebPlugin.registerWith(registrar);
  FilePickerWeb.registerWith(registrar);
  FluttertoastWebPlugin.registerWith(registrar);
  JustAudioPlugin.registerWith(registrar);
  SharedPreferencesPlugin.registerWith(registrar);
  registrar.registerMessageHandler();
}
