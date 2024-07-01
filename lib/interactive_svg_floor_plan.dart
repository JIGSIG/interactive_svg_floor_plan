library interactive_svg_floor_plan;

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:xml/xml.dart';

const Color defaultColor = Colors.transparent;

class SvgPart {
  final String? id;
  final String path;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final String name;
  final String? type;

  SvgPart({
    required this.id,
    required this.path,
    required this.fillColor,
    required this.strokeColor,
    this.strokeWidth = 2.0,
    required this.name,
    this.type,
  });

  @override
  String toString() {
    return 'SvgPart{id: $id, path: $path, fillColor: $fillColor, strokeColor: $strokeColor, name: $name}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SvgPart &&
        other.id == id &&
        other.path == path &&
        other.fillColor == fillColor &&
        other.strokeColor == strokeColor &&
        other.strokeWidth == strokeWidth &&
        other.name == name;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    path.hashCode ^
    fillColor.hashCode ^
    strokeColor.hashCode ^
    strokeWidth.hashCode ^
    name.hashCode;
  }
}

final colorMap = {
  'aliceblue': 'F0F8FF',
  'antiquewhite': 'FAEBD7',
  'aqua': '00FFFF',
  'aquamarine': '7FFFD4',
  'azure': 'F0FFFF',
  'beige': 'F5F5DC',
  'bisque': 'FFE4C4',
  'black': '000000',
  'blanchedalmond': 'FFEBCD',
  'blue': '0000FF',
  'blueviolet': '8A2BE2',
  'brown': 'A52A2A',
  'burlywood': 'DEB887',
  'cadetblue': '5F9EA0',
  'chartreuse': '7FFF00',
  'chocolate': 'D2691E',
  'coral': 'FF7F50',
  'cornflowerblue': '6495ED',
  'cornsilk': 'FFF8DC',
  'crimson': 'DC143C',
  'cyan': '00FFFF',
  'darkblue': '00008B',
  'darkcyan': '008B8B',
  'darkgoldenrod': 'B8860B',
  'darkgray': 'A9A9A9',
  'darkgreen': '006400',
  'darkkhaki': 'BDB76B',
  'darkmagenta': '8B008B',
  'darkolivegreen': '556B2F',
  'darkorange': 'FF8C00',
  'darkorchid': '9932CC',
  'darkred': '8B0000',
  'darksalmon': 'E9967A',
  'darkseagreen': '8FBC8F',
  'darkslateblue': '483D8B',
  'darkslategray': '2F4F4F',
  'darkturquoise': '00CED1',
  'darkviolet': '9400D3',
  'deeppink': 'FF1493',
  'deepskyblue': '00BFFF',
  'dimgray': '696969',
  'dodgerblue': '1E90FF',
  'firebrick': 'B22222',
  'floralwhite': 'FFFAF0',
  'forestgreen': '228B22',
  'fuchsia': 'FF00FF',
  'gainsboro': 'DCDCDC',
  'ghostwhite': 'F8F8FF',
  'gold': 'FFD700',
  'goldenrod': 'DAA520',
  'gray': '808080',
  'green': '008000',
  'greenyellow': 'ADFF2F',
  'honeydew': 'F0FFF0',
  'hotpink': 'FF69B4',
  'indianred': 'CD5C5C',
  'indigo': '4B0082',
  'ivory': 'FFFFF0',
  'khaki': 'F0E68C',
  'lavender': 'E6E6FA',
  'lavenderblush': 'FFF0F5',
  'lawngreen': '7CFC00',
  'lemonchiffon': 'FFFACD',
  'lightblue': 'ADD8E6',
  'lightcoral': 'F08080',
  'lightcyan': 'E0FFFF',
  'lightgoldenrodyellow': 'FAFAD2',
  'lightgray': 'D3D3D3',
  'lightgreen': '90EE90',
  'lightpink': 'FFB6C1',
  'lightsalmon': 'FFA07A',
  'lightseagreen': '20B2AA',
  'lightskyblue': '87CEFA',
  'lightslategray': '778899',
  'lightsteelblue': 'B0C4DE',
  'lightyellow': 'FFFFE0',
  'lime': '00FF00',
  'limegreen': '32CD32',
  'linen': 'FAF0E6',
  'magenta': 'FF00FF',
  'maroon': '800000',
  'mediumaquamarine': '66CDAA',
  'mediumblue': '0000CD',
  'mediumorchid': 'BA55D3',
  'mediumpurple': '9370DB',
  'mediumseagreen': '3CB371',
  'mediumslateblue': '7B68EE',
  'mediumspringgreen': '00FA9A',
  'mediumturquoise': '48D1CC',
  'mediumvioletred': 'C71585',
  'midnightblue': '191970',
  'mintcream': 'F5FFFA',
  'mistyrose': 'FFE4E1',
  'moccasin': 'FFE4B5',
  'navajowhite': 'FFDEAD',
  'navy': '000080',
  'oldlace': 'FDF5E6',
  'olive': '808000',
  'olivedrab': '6B8E23',
  'orange': 'FFA500',
  'orangered': 'FF4500',
  'orchid': 'DA70D6',
  'palegoldenrod': 'EEE8AA',
  'palegreen': '98FB98',
  'paleturquoise': 'AFEEEE',
  'palevioletred': 'DB7093',
  'papayawhip': 'FFEFD5',
  'peachpuff': 'FFDAB9',
  'peru': 'CD853F',
  'pink': 'FFC0CB',
  'plum': 'DDA0DD',
  'powderblue': 'B0E0E6',
  'purple': '800080',
  'rebeccapurple': '663399',
  'red': 'FF0000',
  'rosybrown': 'BC8F8F',
  'royalblue': '4169E1',
  'saddlebrown': '8B4513',
  'salmon': 'FA8072',
  'sandybrown': 'F4A460',
  'seagreen': '2E8B57',
  'seashell': 'FFF5EE',
  'sienna': 'A0522D',
  'silver': 'C0C0C0',
  'skyblue': '87CEEB',
  'slateblue': '6A5ACD',
  'slategray': '708090',
  'snow': 'FFFAFA',
  'springgreen': '00FF7F',
  'steelblue': '4682B4',
  'tan': 'D2B48C',
  'teal': '008080',
  'thistle': 'D8BFD8',
  'tomato': 'FF6347',
  'turquoise': '40E0D0',
  'violet': 'EE82EE',
  'wheat': 'F5DEB3',
  'white': 'FFFFFF',
  'whitesmoke': 'F5F5F5',
  'yellow': 'FFFF00',
  'yellowgreen': '9ACD32'
};

Color convertColorToHex(String? color) {
  if (color == null) {
    return defaultColor;
  }

  if (color.startsWith('#')) {
    color = color.substring(1);

    if (color.length == 6) {
      color = "FF${color.toUpperCase()}";
      return Color(int.parse(color, radix: 16));
    }

    if (color.length == 3) {
      color = color.split('').map((c) => c * 2).join('');
      color = "FF${color.toUpperCase()}";
      return Color(int.parse(color, radix: 16));
    }
  }

  // Handle rgb/rgba format
  if (color.startsWith('rgb')) {
    final rgba = color.replaceAll(RegExp(r'[^\d,]'), '').split(',');
    final r = int.parse(rgba[0]);
    final g = int.parse(rgba[1]);
    final b = int.parse(rgba[2]);
    color = ((1 << 24) + (r << 16) + (g << 8) + b)
        .toRadixString(16)
        .substring(1)
        .toUpperCase();
    color = "FF$color";
    return Color(int.parse(color, radix: 16));
  }

  if (colorMap.containsKey(color.toLowerCase())) {
    color = "FF${colorMap[color.toLowerCase()]!}";
    return Color(int.parse(color, radix: 16));
  }

  return defaultColor; // Default to black if color format is unknown
}

class InteractiveSVGFloorPlan extends StatefulWidget {
  final String plan;
  final Color highlightColor;
  final double highlightStrokeWeight;
  final double fillOpacity;
  final void Function(SvgPart part) onPartSelected;
  final List<String> selectedParts;
  final bool multiSelect;

  const InteractiveSVGFloorPlan({
    super.key,
    required this.plan,
    this.highlightColor = Colors.red,
    this.highlightStrokeWeight = 2.0,
    this.fillOpacity = 1.0,
    required this.onPartSelected,
    this.selectedParts = const [],
    this.multiSelect = false,
  });

  @override
  State<InteractiveSVGFloorPlan> createState() =>
      _InteractiveSVGFloorPlanState();
}

class _InteractiveSVGFloorPlanState extends State<InteractiveSVGFloorPlan> {
  List<SvgPart> parts = [];

  // Selection rectangle state variables
  Offset? _startSelection;
  Offset? _endSelection;
  bool _isSelecting = false;
  List<SvgPart> _selectedParts = [];

  // Default canvas size (3000x2250)
  Size canvasSize = const Size(3000, 2250);

  final TransformationController _transformationController =
  TransformationController();

  double scaleX = 1.0;
  double scaleY = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await loadSvgImage(svgImage: widget.plan);
      setState(() {});
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(builder: (context, constraints) {
        double maxWidth = constraints.maxWidth - 50;
        double maxHeight = constraints.maxHeight - 50;

        scaleX = maxWidth / canvasSize.width;
        scaleY = maxHeight / canvasSize.height;

        if (scaleY > scaleX) scaleY = scaleX;

        double translateY = canvasSize.height * .02;
        double translateX = canvasSize.width * .02;

        return GestureDetector(
          onTapDown: widget.multiSelect ? _multiSelectTapDown : _singleSelectTapDown,
          onPanUpdate: (details) {
            if (!widget.multiSelect) return;
            setState(() {
              _endSelection = details.localPosition;
            });
          },
          onHorizontalDragUpdate: (details) {
            if (!widget.multiSelect) return;
            setState(() {
              _endSelection = details.localPosition;
            });
          },
          onHorizontalDragEnd: (details) {
            if (!widget.multiSelect) return;
            _selectPartsInRect(_getSelectionRect());
            setState(() {
              _startSelection = null;
              _endSelection = null;
              _isSelecting = false;
            });
            log("Pan Ended");
          },
          onPanEnd: (details) {
            if (!widget.multiSelect) return;
            _selectPartsInRect(_getSelectionRect());
            setState(() {
              _startSelection = null;
              _endSelection = null;
              _isSelecting = false;
            });
            log("Pan Ended");
          },
          // onPanStart: (details) {
          //   if (!widget.multiSelect) return;
          //   log("Pan Started");
          //   setState(() {
          //     _isSelecting = true;
          //     _startSelection = details.localPosition;
          //     _endSelection = details.localPosition;
          //   });
          // },
          // onPanUpdate: (details) {
          //   if (!widget.multiSelect) return;
          //   setState(() {
          //     _endSelection = details.localPosition;
          //   });
          // },
          // onPanEnd: (details) {
          //   if (!widget.multiSelect) return;
          //   _selectPartsInRect(_getSelectionRect());
          //   setState(() {
          //     _startSelection = null;
          //     _endSelection = null;
          //     _isSelecting = false;
          //   });
          //   log("Pan Ended");
          // },
          child: Stack(
            children: [
              Container(
                height: constraints.maxHeight,
                width: constraints.maxWidth,
                color: Colors.transparent,
                child: InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  minScale: .75,
                  maxScale: 5,
                  panEnabled: !_isSelecting,
                  // scaleEnabled: !widget.multiSelect,
                  panAxis: PanAxis.aligned,
                  transformationController: _transformationController,
                  child: Transform(
                    transform: Matrix4.identity()..scale(scaleX, scaleY)..translate(translateX, translateY),
                    child: CustomPaint(
                      painter: SvgPathPainter(
                        parts: parts,
                        selectedParts: parts
                            .where((part) => widget.selectedParts.contains(part.id))
                            .toList(),
                        highlightColor: widget.highlightColor,
                        highlightStrokeWeight: widget.highlightStrokeWeight,
                      ),
                    ),
                  ),
                ),
              ),
              if (_isSelecting && _startSelection != null && _endSelection != null && widget.multiSelect) ... [
                CustomPaint(
                  painter: SelectionRectPainter(
                    rect: _getSelectionRect(),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  void _singleSelectTapDown(details) {
    if (widget.multiSelect) return;
    Vector3 translation =
    _transformationController.value.getTranslation();
    double newScaleFactor =
    _transformationController.value.getMaxScaleOnAxis();

    // scale the local position to the original size
    final localPosition = Offset(
      ((details.localPosition.dx / scaleX) - (translation.x * scaleX)) /
          newScaleFactor,
      ((details.localPosition.dy / scaleY) - (translation.y * scaleY)) /
          newScaleFactor,
    );

    log("Local Position: $localPosition");

    bool isPartSelected = false;
    for (var part in parts) {
      final path = parseSvgPathData(part.path);
      if (path.contains(localPosition) && part.id != null) {
        isPartSelected = true;
        onPartSelected(part);
        break;
      }
    }
    // if (!isPartSelected) {
    //   setState(() {});
    // }
  }

  void _multiSelectTapDown(details) {
    if (!widget.multiSelect) return;
    log("Pan Started");
    setState(() {
      _isSelecting = true;
      _startSelection = details.localPosition;
      _endSelection = details.localPosition;
    });
  }

  Rect _getSelectionRect() {
    if (_startSelection == null || _endSelection == null) return Rect.zero;
    return Rect.fromPoints(_startSelection!, _endSelection!);
  }

  void _selectPartsInRect(Rect selectionRect) {

    Vector3 translation =
    _transformationController.value.getTranslation();
    double newScaleFactor =
    _transformationController.value.getMaxScaleOnAxis();

    Offset start = Offset(
      ((selectionRect.left / scaleX) - (translation.x * scaleX)) / newScaleFactor,
      ((selectionRect.top / scaleY) - (translation.y * scaleY)) / newScaleFactor,
    );
    Offset end = Offset(
      ((selectionRect.right / scaleX) - (translation.x * scaleX)) / newScaleFactor,
      ((selectionRect.bottom / scaleY) - (translation.y * scaleY)) / newScaleFactor,
    );

    Rect newRect = Rect.fromPoints(start, end);

    List<SvgPart> selected = [];
    for (var part in parts) {
      final path = parseSvgPathData(part.path);
      if (path.getBounds().overlaps(newRect)) {
        selected.add(part);
      }
    }
    setState(() {
      _selectedParts = selected;
    });
    for (var element in _selectedParts) {
      widget.onPartSelected(element);
    }
  }

  void onPartSelected(SvgPart part) {
    widget.onPartSelected(part);

    setState(() {});
  }

  SvgPart parseElementToSvgPart(XmlElement element, String type) {
    String? id = element.getAttribute('id');
    if (id == "null" || id == null || id.isEmpty) {
      id = null;
    }
    Color fillColor = convertColorToHex(element.getAttribute('fill'));
    if (fillColor != Colors.transparent && id != null) {
      fillColor = fillColor.withOpacity(widget.fillOpacity);
    }
    final Color strokeColor = convertColorToHex(element.getAttribute('stroke'));
    final double strokeWidth =
    double.parse(element.getAttribute('stroke-width') ?? '2');
    log('Stroke Width: $strokeWidth');
    final String name = element.getAttribute('aria-label') ?? '';

    String path;
    switch (type) {
      case 'rect':
        final x = element.getAttribute('x') ?? '0';
        final y = element.getAttribute('y') ?? '0';
        final width = element.getAttribute('width') ?? '0';
        final height = element.getAttribute('height') ?? '0';
        path = 'M$x,$y h$width v$height h-$width Z';
        break;
      case 'polygon':
        final points = element.getAttribute('points') ?? '';
        path =
        'M${points.split(' ').map((e) => e.replaceAll(',', ' ')).join(' L')} Z';
        break;
        final pointList =
        points.split(RegExp(r'[\s,]+')).where((s) => s.isNotEmpty).toList();
        if (pointList.length % 2 != 0) {
          log('Invalid points attribute in polygon element: $points');
          path = '';
        } else {
          path =
          'M${pointList.asMap().entries.map((e) => '${e.value}${e.key % 2 == 0 ? ',' : ' '}').join()} Z';
        }
        break;
      case 'polyline':
        final points = element.getAttribute('points') ?? '';
        final pointList =
        points.split(RegExp(r'[\s,]+')).where((s) => s.isNotEmpty).toList();
        if (pointList.length % 2 != 0) {
          log('Invalid points attribute in polyline element: $points');
          path = '';
        } else {
          path =
          'M${pointList.asMap().entries.map((e) => '${e.value}${e.key % 2 == 0 ? ',' : ' '}').join()}';
        }
        break;
      case 'line':
        final x1 = element.getAttribute('x1') ?? '0';
        final y1 = element.getAttribute('y1') ?? '0';
        final x2 = element.getAttribute('x2') ?? '0';
        final y2 = element.getAttribute('y2') ?? '0';
        path = 'M$x1,$y1 L$x2,$y2';
        break;
      case 'circle':
        final cx = double.tryParse(element.getAttribute('cx') ?? '0') ?? 0;
        final cy = double.tryParse(element.getAttribute('cy') ?? '0') ?? 0;
        final r = double.tryParse(element.getAttribute('r') ?? '0') ?? 0;
        path =
        'M${cx + r},$cy A$r,$r 0 1,1 ${cx - r},$cy A$r,$r 0 1,1 ${cx + r},$cy';
        break;
      case 'ellipse':
        final cx = double.tryParse(element.getAttribute('cx') ?? '0') ?? 0;
        final cy = double.tryParse(element.getAttribute('cy') ?? '0') ?? 0;
        final rx = double.tryParse(element.getAttribute('rx') ?? '0') ?? 0;
        final ry = double.tryParse(element.getAttribute('ry') ?? '0') ?? 0;
        path =
        'M${cx + rx},$cy A$rx,$ry 0 1,1 ${cx - rx},$cy A$rx,$ry 0 1,1 ${cx + rx},$cy';
        break;
      case 'path':
        path = element.getAttribute('d') ?? '';
        break;
      default:
        path = '';
    }

    return SvgPart(
      id: id ?? (parts.isEmpty ? null : path),
      path: path,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      name: name,
      type: type,
    );
  }

  Future<List<SvgPart>> loadSvgImage({required String svgImage}) async {
    String generalString = await rootBundle.loadString(svgImage);

    XmlDocument document = XmlDocument.parse(generalString);

    canvasSize = Size(
      double.parse(document.rootElement.getAttribute('width') ?? '3000'),
      double.parse(document.rootElement.getAttribute('height') ?? '2250'),
    );

    // Combine queries to minimize DOM parsing time

    // Handle <rect> elements
    document.findAllElements('rect').forEach(
            (element) => parts.add(parseElementToSvgPart(element, 'rect')));
    // Handle <polygon> elements
    document.findAllElements('polygon').forEach(
            (element) => parts.add(parseElementToSvgPart(element, 'polygon')));
    // Handle <polyline> elements
    document.findAllElements('polyline').forEach(
            (element) => parts.add(parseElementToSvgPart(element, 'polyline')));
    // Handle <line> elements
    document.findAllElements('line').forEach(
            (element) => parts.add(parseElementToSvgPart(element, 'line')));
    // Handle <circle> elements
    document.findAllElements('circle').forEach(
            (element) => parts.add(parseElementToSvgPart(element, 'circle')));
    // Handle <ellipse> elements
    document.findAllElements('ellipse').forEach(
            (element) => parts.add(parseElementToSvgPart(element, 'ellipse')));
    // Handle <path> elements
    document.findAllElements('path').forEach(
            (element) => parts.add(parseElementToSvgPart(element, 'path')));

    return parts;
  }
}

class SvgPathPainter extends CustomPainter {
  final List<SvgPart> parts;
  final List<SvgPart> selectedParts;
  final Color highlightColor;
  final double highlightStrokeWeight;

  SvgPathPainter({
    required this.parts,
    this.selectedParts = const [],
    required this.highlightColor,
    required this.highlightStrokeWeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var part in parts) {
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selectedParts.isEmpty
            ? part.strokeWidth
            : (selectedParts.contains(part)
            ? part.strokeWidth * highlightStrokeWeight
            : part.strokeWidth)
        ..color = part.strokeColor;

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = selectedParts.isEmpty
            ? part.fillColor
            : (selectedParts.contains(part) ? highlightColor : part.fillColor);

      try {
        final path = parseSvgPathData(part.path);
        canvas.drawPath(path, strokePaint);
        canvas.drawPath(path, fillPaint);
      } catch (e) {
        log(e.toString(), name: part.type.toString());
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class SelectionRectPainter extends CustomPainter {
  final Rect rect;

  SelectionRectPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
