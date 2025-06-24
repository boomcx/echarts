library flutter_echarts;

import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';

import 'package:webview_flutter/webview_flutter.dart';

import 'echarts_script.dart' show echartsScript;

/// <!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=0, target-densitydpi=device-dpi" /><style type="text/css">body,html,#chart{height: 100%;width: 100%;margin: 0px;}div {-webkit-tap-highlight-color:rgba(255,255,255,0);}</style></head><body><div id="chart" /></body></html>
/// 'data:text/html;base64,' + base64Encode(const Utf8Encoder().convert( /* STRING ABOVE */ ))
// const htmlBase64 =
// 'data:text/html;base64,PCFET0NUWVBFIGh0bWw+PGh0bWw+PGhlYWQ+PG1ldGEgY2hhcnNldD0idXRmLTgiPjxtZXRhIG5hbWU9InZpZXdwb3J0IiBjb250ZW50PSJ3aWR0aD1kZXZpY2Utd2lkdGgsIGluaXRpYWwtc2NhbGU9MS4wLCBtYXhpbXVtLXNjYWxlPTEuMCwgbWluaW11bS1zY2FsZT0xLjAsIHVzZXItc2NhbGFibGU9MCwgdGFyZ2V0LWRlbnNpdHlkcGk9ZGV2aWNlLWRwaSIgLz48c3R5bGUgdHlwZT0idGV4dC9jc3MiPmJvZHksaHRtbCwjY2hhcnR7aGVpZ2h0OiAxMDAlO3dpZHRoOiAxMDAlO21hcmdpbjogMHB4O31kaXYgey13ZWJraXQtdGFwLWhpZ2hsaWdodC1jb2xvcjpyZ2JhKDI1NSwyNTUsMjU1LDApO308L3N0eWxlPjwvaGVhZD48Ym9keT48ZGl2IGlkPSJjaGFydCIgLz48L2JvZHk+PC9odG1sPg==';

const document =
    ' <!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=0, target-densitydpi=device-dpi" /><style type="text/css">body,html,#chart{height: 100%;width: 100%;margin: 0px;}div {-webkit-tap-highlight-color:rgba(255,255,255,0);}</style></head><body><div id="chart" /></body></html>';

class Echarts extends StatefulWidget {
  const Echarts(
      {Key? key,
      required this.option,
      this.extraScript = '',
      this.onMessage,
      this.extensions = const [],
      this.notMerge = true,
      this.theme,
      this.captureAllGestures = false,
      this.captureHorizontalGestures = false,
      this.captureVerticalGestures = false,
      this.onLoad,
      this.onWebResourceError,
      this.reloadAfterInit = false})
      : super(key: key);

  final String option;

  final String extraScript;

  final void Function(String message)? onMessage;

  final List<String> extensions;

  final String? theme;

  /// 指定更新模式
  final bool notMerge;

  final bool captureAllGestures;

  final bool captureHorizontalGestures;

  final bool captureVerticalGestures;

  final void Function(WebViewController)? onLoad;

  final void Function(WebViewController, Exception)? onWebResourceError;

  final bool reloadAfterInit;

  @override
  State<Echarts> createState() => _EchartsState();
}

class _EchartsState extends State<Echarts> {
  late String _curOptionJs;

  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(const Color(0x00000000))
    ..loadHtmlString(document)
    ..setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          // Update loading bar.
          // print('progress - $progress');
        },
        onPageStarted: (String url) {},
        onPageFinished: (String url) {
          initEcharts();
        },
        onWebResourceError: (WebResourceError error) {
          if (widget.onWebResourceError != null) {
            widget.onWebResourceError!(_controller, Exception(error));
          }
        },
        // onNavigationRequest: (NavigationRequest request) {
        //   if (request.url.startsWith('https://www.youtube.com/')) {
        //     return NavigationDecision.prevent;
        //   }
        //   return NavigationDecision.navigate;
        // },
      ),
    )
    ..addJavaScriptChannel(
      'Messager',
      onMessageReceived: (javascriptMessage) {
        if (widget.onMessage != null) {
          widget.onMessage!(javascriptMessage.message);
        }
      },
    );

  @override
  void initState() {
    super.initState();
    _curOptionJs = widget.option;

    if (widget.reloadAfterInit) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _controller.reload();
      });
    }
  }

  void initEcharts() async {
    final extensionsStr = widget.extensions.isNotEmpty
        ? widget.extensions.reduce((value, element) => '$value\n$element')
        : '';
    final themeStr = widget.theme != null ? '\'${widget.theme}\'' : 'null';

    await _controller.runJavaScript('''
      $echartsScript
      $extensionsStr
      var chart = echarts.init(document.getElementById('chart'), $themeStr);
      ${widget.extraScript}
      chart.setOption($_curOptionJs, true);
    ''');

    if (widget.onLoad != null) {
      widget.onLoad!(_controller);
    }
  }

  Set<Factory<OneSequenceGestureRecognizer>> getGestureRecognizers() {
    Set<Factory<OneSequenceGestureRecognizer>> set = Set();
    if (widget.captureAllGestures || widget.captureHorizontalGestures) {
      set.add(Factory<HorizontalDragGestureRecognizer>(() {
        return HorizontalDragGestureRecognizer()
          ..onStart = (DragStartDetails details) {}
          ..onUpdate = (DragUpdateDetails details) {}
          ..onDown = (DragDownDetails details) {}
          ..onCancel = () {}
          ..onEnd = (DragEndDetails details) {};
      }));
    }
    if (widget.captureAllGestures || widget.captureVerticalGestures) {
      set.add(Factory<VerticalDragGestureRecognizer>(() {
        return VerticalDragGestureRecognizer()
          ..onStart = (DragStartDetails details) {}
          ..onUpdate = (DragUpdateDetails details) {}
          ..onDown = (DragDownDetails details) {}
          ..onCancel = () {}
          ..onEnd = (DragEndDetails details) {};
      }));
    }
    return set;
  }

  void update(String preOption, String preExtra) async {
    _curOptionJs = widget.option;
    if (_curOptionJs != preOption || widget.extraScript != preExtra) {
      await _controller.runJavaScript('''
        try {
          ${widget.extraScript}
          chart.setOption($_curOptionJs, ${widget.notMerge});
        } catch(e) {
        }
      ''');
    }
  }

  @override
  void didUpdateWidget(Echarts oldWidget) {
    super.didUpdateWidget(oldWidget);
    update(oldWidget.option, oldWidget.extraScript);
  }

  @override
  void dispose() {
    _controller.clearCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(
      controller: _controller,
      gestureRecognizers: getGestureRecognizers(),
    );
  }
}
