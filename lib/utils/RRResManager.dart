import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_yyets/main.dart';
import 'package:flutter_yyets/utils/toast.dart';

///
/// 各平台下载Api
///
class RRResManager {
//  static Map<String, void Function(dynamic atgs)> methods = {
//    "goDetail": (args) {
//      return Navigator.pushNamed(MyApp.navigatorKey.currentContext, "/detail",
//          arguments: args);
//    },
//  };

  static var methodChannel = MethodChannel("cn.vove7.flutter_yyets/channel");

  static List _eventListeners = [];
  static List _onStopListeners = [];

  /// api是否支持运行平台
  static bool isSupportThisPlatForm = Platform.isAndroid;

  static String get unSupportMsg => "此功能暂仅支持安卓平台";

  static bool checkPlatform() {
    if (isSupportThisPlatForm) {
      return true;
    } else {
      toast(unSupportMsg);
      return false;
    }
  }

  static bool ecIsInit = false;
  static EventChannel eventChannel =
  EventChannel('cn.vove7.flutter_yyets/download_event');

  static Future getAllItems() async {
    return jsonDecode(await methodChannel.invokeMethod("getAllItems"));
  }

  static Future<Map<dynamic, dynamic>> getFilmStatus(List<Map> data) {
    return methodChannel.invokeMethod("getFilmStatus", data);
  }

  static Future addTask(String id,
      String rrUri,
      String filmImg, {
        String filmName,
        String season,
        String episode,
      }) async {
    Map data = parseRRUri(rrUri);
    if (filmName != null) {
      data['filmName'] = filmName;
    }
    data['season'] = season;
    data['episode'] = episode;

    data['filmId'] = id;
    data['p4pUrl'] = rrUri;
    data['filmImg'] = filmImg;
    print(data);
    return methodChannel.invokeMethod("startDownload", data).then((result) {
      print(result);
    });
  }

  static Future resumeByFileId(String fileId) {
    return methodChannel.invokeMethod("resumeByFileId", fileId);
  }

  static Future pauseByFileId(String fileId) {
    return methodChannel.invokeMethod("pauseByFileId", fileId);
  }

  static Future pauseAll() {
    return methodChannel.invokeMethod("pauseAll");
  }

  static Future resumeAll() {
    return methodChannel.invokeMethod("resumeAll");
  }

  static Future getStatus(Map bean) {
    return methodChannel.invokeMethod("getStatus", bean);
  }

  static Future<bool> deleteDownload(String fileId) {
    return methodChannel.invokeMethod("deleteDownload", fileId);
  }

  //yyets://N=....mp4|S=....|H=.....|
  static Map parseRRUri(String rrUri) {
    String s = rrUri.substring(8, rrUri.length - 1);
    var ks = {"H": "fileId", "S": "size", "N": "fileName"};
    var data = {};
    s.split('|').forEach((item) {
      List ss = item.split('=');
      data[ks[ss[0]]] = ss[1];
    });
    return data;
  }

  static Future playByExternal(filename) {
    return methodChannel
        .invokeMethod("playByExternal", filename)
        .catchError((e) {
      toast(e);
    });
  }

  static void _ensureEventChannel() {
    if (!ecIsInit) {
      ecIsInit = true;
      eventChannel.receiveBroadcastStream().listen((data) {
        print("eventChannel -> " + data);
        if (data == "onStop") {
          _onStopListeners.forEach((e) => e());
        } else {
          _eventListeners.forEach((lis) {
            lis(data);
          });
        }
      });
    }
  }

  static void addEventListener<T>(void onData(T)) {
    _ensureEventChannel();
    _eventListeners.add(onData);
  }

  static void addOnStopListener(void onStop()) {
    _ensureEventChannel();
    _onStopListeners.add(onStop);
  }

  static void removeEventListener<T>(void onData(T data)) {
    _eventListeners.remove(onData);
  }

  static void removeOnStopListener<T>(void onStop()) {
    _onStopListeners.remove(onStop);
  }
}
