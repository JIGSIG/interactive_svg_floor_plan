library interactive_svg_floor_plan;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import 'package:xml/xml.dart';
import 'dart:math' as math;

extension ExtensionList<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test, {T? Function()? orElse}) {
    try {
      return firstWhere(test);
    } catch (e) {
      return orElse?.call();
    }
  }

  T? lastWhereOrNull(bool Function(T) test) {
    try {
      return lastWhere(test);
    } catch (e) {
      return null;
    }
  }

  bool compareTo(List<T?> other) {
    if (length != other.length) {
      return false;
    }
    for (int i = 0; i < length; i++) {
      if (elementAt(i) != other.elementAt(i)) {
        return false;
      }
    }
    return true;
  }

  List<T>? whereOrNull(bool Function(T) test) {
    try {
      return where(test).toList();
    } catch (e) {
      return null;
    }
  }

  List<T> whereOrEmpty(bool Function(T) test) {
    try {
      return where(test).toList();
    } catch (e) {
      return <T>[];
    }
  }
}

const Color defaultColor = Colors.transparent;

class SvgPart {
  final String? id;
  final String path;
  final Path parsedPath;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final String name;
  final String? type;
  final SvgPartType partType;

  Rect? scaledRect;
  Rect rect = Rect.zero;

  SvgPart({
    required this.id,
    required this.path,
    required this.parsedPath,
    required this.fillColor,
    required this.strokeColor,
    this.strokeWidth = 2.0,
    required this.name,
    this.type,
    required this.partType,
  }) {
    rect = parsedPath.getBounds();
  }

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

  SvgPart copyWith({Rect? scaledRect}) {
    return SvgPart(
      id: id,
      path: path,
      parsedPath: parsedPath,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      name: name,
      type: type,
      partType: partType,
    );
  }
}

enum SvgPartType { room, door, window, wall, floor, ceiling, furniture, other }

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

Color convertColorToHex(String? color, {Color noneColor = defaultColor}) {
  if (color == null) {
    return defaultColor;
  }

  if (color == 'background') {
    return noneColor;
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

class InteractiveSVGFloorPlanController {
  List<SvgPart> _parts = [];
  List<SvgPart> _selectedParts = [];
  final TransformationController _transformationController =
      TransformationController();
  VoidCallback? _updateCallback;
  Size canvasSize = const Size(3000, 2250);
  Size canvasRealSize = const Size(3000, 2250);

  Color? _fillColor;
  Color _backgroundColor = defaultColor;
  double _fillOpacity = 1.0;
  Color? _borderColor;
  final String planPath;

  Vector3? center;

  SvgPart? currentlyHoveredPart;

  InteractiveSVGFloorPlanController({required this.planPath}) {
    loadSvgImage(svgImage: planPath);
  }

  List<SvgPart> get parts => _parts;

  TransformationController get transformationController =>
      _transformationController;

  void setColor({
    Color? fillColor,
    Color? borderColor,
    Color backgroundColor = defaultColor,
    double fillOpacity = 1.0,
  }) {
    _fillColor = fillColor;
    _borderColor = borderColor;
    _backgroundColor = backgroundColor;
    _fillOpacity = fillOpacity;
    loadSvgImage(svgImage: '');
  }

  void setParts(List<SvgPart> parts) {
    _parts = parts;
    _notifyUpdate();
  }

  void setUpdateCallback(VoidCallback callback) {
    _updateCallback = callback;
  }

  void _notifyUpdate() {
    if (_updateCallback != null) {
      _updateCallback!();
    }
  }

  void selectMultipleParts(List<String> partIds) {
    _selectedParts = _parts.where((part) => partIds.contains(part.id)).toList();
    _notifyUpdate();
  }

  void selectPart(SvgPart part) {
    if (part.id == null) return;
    if (_selectedParts.contains(part)) {
      _selectedParts.remove(part);
    } else {
      _selectedParts.add(part);
    }
    _notifyUpdate();
  }

  // Example method to load SVG image
  Future<void> loadSvgImage({required String svgImage}) async {
    _parts.clear();

    String generalString = await rootBundle.loadString(svgImage);

    XmlDocument document = XmlDocument.parse(generalString);

    canvasSize = Size(
      double.parse(document.rootElement.getAttribute('width') ?? '3000'),
      double.parse(document.rootElement.getAttribute('height') ?? '2250'),
    );

    // Combine queries to minimize DOM parsing time

    // Handle <rect> elements
    document.findAllElements('rect').forEach(
        (element) => _parts.add(parseElementToSvgPart(element, 'rect')));
    // Handle <polygon> elements
    document.findAllElements('polygon').forEach(
        (element) => _parts.add(parseElementToSvgPart(element, 'polygon')));
    // Handle <polyline> elements
    document.findAllElements('polyline').forEach(
        (element) => _parts.add(parseElementToSvgPart(element, 'polyline')));
    // Handle <line> elements
    document.findAllElements('line').forEach(
        (element) => _parts.add(parseElementToSvgPart(element, 'line')));
    // Handle <circle> elements
    document.findAllElements('circle').forEach(
        (element) => _parts.add(parseElementToSvgPart(element, 'circle')));
    // Handle <ellipse> elements
    document.findAllElements('ellipse').forEach(
        (element) => _parts.add(parseElementToSvgPart(element, 'ellipse')));
    // Handle <path> elements
    document.findAllElements('path').forEach(
        (element) => _parts.add(parseElementToSvgPart(element, 'path')));

    setParts(_parts);
  }

  SvgPart parseElementToSvgPart(XmlElement element, String type) {
    Color strokeColor = convertColorToHex(
      element.getAttribute('stroke'),
      noneColor: _backgroundColor,
    );
    if (strokeColor != _backgroundColor && _borderColor != null) {
      strokeColor = _borderColor!;
    }
    final double strokeWidth =
        double.parse(element.getAttribute('stroke-width') ?? '2');
    final String name = element.getAttribute('name') ?? '';
    final String partTypeString = element.getAttribute('type') ?? '';
    final SvgPartType partType = SvgPartType.values.firstWhere(
      (e) {
        return e.toString().split('.').last == partTypeString;
      },
      orElse: () => SvgPartType.other,
    );
    String? id = element.getAttribute('id');
    if (id == "null" || id == null || id.isEmpty) {
      id = (partType == SvgPartType.room ? _parts.length.toString() : null);
    }
    Color fillColor = _fillColor ??
        convertColorToHex(
          element.getAttribute('fill'),
          noneColor: _backgroundColor,
        );
    if (fillColor != Colors.transparent && id != null) {
      fillColor = fillColor.withOpacity(_fillOpacity);
    }

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

    Path parsedPath = parseSvgPathData(path);

    return SvgPart(
      id: id,
      path: path,
      parsedPath: parsedPath,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      name: name,
      type: type,
      partType: partType,
    );
  }

  void setCanvasRealSize(Size size) {
    canvasRealSize = size;
  }

  void zoomIn() {
    // _transformationController.value *= Matrix4.diagonal3Values(1.1, 1.1, 1);
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (scale >= 2.5) {
      return;
    }
    final position = _transformationController.value.getTranslation();

    _transformationController.value = Matrix4.identity()..scale(scale + 0.1);
    _notifyUpdate();
  }

  void zoomOut() {
    // _transformationController.value *= Matrix4.diagonal3Values(0.9, 0.9, 1);
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (scale < 1) {
      return;
    }
    final position = _transformationController.value.getTranslation();

    _transformationController.value = Matrix4.identity()..scale(scale - 0.1);
    _notifyUpdate();
  }

  void setCenter(Offset offset) {
    center = Vector3(offset.dx, offset.dy, 1);
  }

  void zoomInCenter() {
    final double scale = _transformationController.value.getMaxScaleOnAxis();
    if (scale >= 2.5) {
      return;
    }
    final double scaleFactor = scale + 0.1;

    final Matrix4 matrix = _transformationController.value.clone();
    final Size size = canvasRealSize;

    // Calculate the center point of the canvas
    final Offset center = Offset(
      size.width / 2,
      size.height / 2,
    );

    // Translate to the center, apply scaling, then translate back
    matrix.translate(-center.dx, -center.dy);
    matrix.scale(scaleFactor);
    matrix.translate(center.dx, center.dy);

    _transformationController.value = matrix;
  }

  void zoomOutCenter() {
    final double scale = _transformationController.value.getMaxScaleOnAxis();
    if (scale <= 1) {
      return;
    }
    final double scaleFactor = scale - 0.1;
    final Matrix4 matrix = _transformationController.value.clone();
    final Size size = canvasRealSize;

    // Calculate the center point of the canvas
    final Offset center = Offset(
      size.width / 2,
      size.height / 2,
    );

    // Translate to the center, apply inverse scaling, then translate back
    matrix.translate(-center.dx, -center.dy);
    matrix.scale(1 / scaleFactor);
    matrix.translate(center.dx, center.dy);

    _transformationController.value = matrix;
  }

  bool checkIfPolygon(Path parsedPath) {
    final bounds = parsedPath.getBounds();
    final rect = Rect.fromPoints(bounds.topLeft, bounds.bottomRight);

    return rect.width + rect.height > 0.0;
  }
}

class InteractiveSVGFloorPlan extends StatefulWidget {
  final String? plan;
  final InteractiveSVGFloorPlanController? controller;
  final Color highlightColor;
  final double highlightStrokeWeight;
  final Color? highlightStrokeColor;
  final Color hoverColor;
  final double hoverStrokeWeight;
  final Color? hoverStrokeColor;
  final double fillOpacity;
  final void Function(List<SvgPart> parts) onMultiPartsSelected;
  final void Function(SvgPart part) onSinglePartSelected;
  final List<String> selectedParts;
  final bool multiSelect;
  final Color? borderColor;
  final Color? fillColor;
  final Color? backgroundColor;
  final BoxFit fit;
  final double padding;
  final BorderRadius borderRadius;
  final Color tooltipBackgroundColor;

  InteractiveSVGFloorPlan({
    super.key,
    this.plan,
    this.controller,
    this.highlightColor = Colors.red,
    this.highlightStrokeWeight = 2.0,
    this.highlightStrokeColor,
    this.hoverColor = Colors.blue,
    this.hoverStrokeWeight = 2.0,
    this.hoverStrokeColor,
    this.fillOpacity = 1.0,
    required this.onMultiPartsSelected,
    required this.onSinglePartSelected,
    this.selectedParts = const [],
    this.multiSelect = false,
    this.borderColor,
    this.fillColor,
    this.backgroundColor,
    this.fit = BoxFit.contain,
    this.padding = 0.0,
    this.borderRadius = BorderRadius.zero,
    this.tooltipBackgroundColor = const Color(0xFF0546C7),
  }) {
    assert(plan != null || controller != null);
  }

  @override
  State<InteractiveSVGFloorPlan> createState() =>
      _InteractiveSVGFloorPlanState();
}

class _InteractiveSVGFloorPlanState extends State<InteractiveSVGFloorPlan> {
  // List<SvgPart> parts = [];

  // Selection rectangle state variables
  Offset? _startSelection;
  Offset? _endSelection;
  bool _isSelecting = false;
  List<SvgPart> _selectedParts = [];

  // Default canvas size (3000x2250)
  // Size canvasSize = const Size(3000, 2250);

  late final InteractiveSVGFloorPlanController _controller;

  double scaleX = 1.0;
  double scaleY = 1.0;

  double baseScaleX = 1.0;
  double baseScaleY = 1.0;

  double translateX = 0.0;
  double translateY = 0.0;

  bool disableScale = false;
  bool disablePan = false;

  TapDownDetails? currentPositonDetails;
  TapDownDetails? currentPositonDetails2;

  double maxWidth = 0.0;
  double maxHeight = 0.0;

  double imageWidth = 0.0;
  double imageHeight = 0.0;

  Matrix4 oldTransform = Matrix4.identity();

  SvgPart? ajaccio;

  @override
  void initState() {
    _controller = widget.controller ??
        InteractiveSVGFloorPlanController(planPath: widget.plan!);
    super.initState();
    _controller.setUpdateCallback(() {
      setState(() {});
    });
    _controller.transformationController.addListener(() {
      if (oldTransform.getMaxScaleOnAxis() ==
          _controller.transformationController.value.getMaxScaleOnAxis()) {
        return;
      }
      oldTransform = _controller.transformationController.value;
      final scale =
          _controller.transformationController.value.getMaxScaleOnAxis();
      for (int i = 0; i < _controller.parts.length; i++) {
        final part = _controller.parts[i];
        if (part.partType != SvgPartType.room) continue;
        final bounds = part.parsedPath.getBounds();
        Rect scaledRect = Rect.fromPoints(
          Offset(bounds.left * scaleX * scale, bounds.top * scaleY * scale),
          Offset(bounds.right * scaleX * scale, bounds.bottom * scaleY * scale),
        );

        _controller.parts[i].scaledRect = scaledRect;
        if (part.name == "Ajaccio") {
          ajaccio = _controller.parts[i];
        }
      }
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _controller.zoomIn();
        _controller.zoomOut();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: widget.borderRadius,
      // color: Colors.transparent,
      child: LayoutBuilder(builder: (context, constraints) {
        maxWidth = constraints.maxWidth;
        maxHeight = constraints.maxHeight;

        baseScaleX = maxWidth / _controller.canvasSize.width;
        baseScaleY = maxHeight / _controller.canvasSize.height;

        double ratioFromPaddingX =
            1.0 - (widget.padding / _controller.canvasSize.width);
        double ratioFromPaddingY =
            1.0 - (widget.padding / _controller.canvasSize.height);
        baseScaleX = ratioFromPaddingX * baseScaleX;
        baseScaleY = ratioFromPaddingY * baseScaleY;
        scaleX = baseScaleX;
        scaleY = baseScaleY;

        _handleFit();

        imageWidth = _controller.canvasSize.width * scaleX;
        imageHeight = _controller.canvasSize.height * scaleY;

        translateX = ((maxWidth - imageWidth) / 2) / scaleX;
        translateY = ((maxHeight - imageHeight) / 2) / scaleY;

        Widget child = MouseRegion(
          cursor: SystemMouseCursors.click,
          onHover: _displayTooltip,
          child: GestureDetector(
            onTapDown: (details) {
              currentPositonDetails2 = details;
              setState(() {});
            },
            onTap: () {
              if (currentPositonDetails2 != null) {
                _singleSelectTapDown(currentPositonDetails2!);
              }
            },
            onDoubleTap: () {
              // Reset the transformation controller
              _controller.transformationController.value = Matrix4.identity();
            },
            onLongPressStart: _multiSelectTapDown,
            onLongPressMoveUpdate: (details) {
              if (!widget.multiSelect) return;
              setState(() {
                disablePan = true;
                _isSelecting = true;
                _startSelection ??= details.localPosition;
                _endSelection = details.localPosition;
              });
            },
            onLongPressEnd: (details) {
              if (!widget.multiSelect) return;
              _selectPartsInRect(_getSelectionRect());
              setState(() {
                disablePan = false;
                _startSelection = null;
                _endSelection = null;
                _isSelecting = false;
              });
            },
            child: SizedBox(
              height: maxHeight,
              width: maxWidth,
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: .8,
                maxScale: 4.5,
                panEnabled: true,
                scaleEnabled: true,
                panAxis: PanAxis.aligned,
                transformationController: _controller.transformationController,
                child: ClipRRect(
                  borderRadius: widget.borderRadius,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..scale(scaleX, scaleY)
                      ..translate(translateX, translateY),
                    child: CustomPaint(
                      painter: SvgPathPainter(
                        parts: _controller.parts,
                        hoveredPart:
                            _controller.currentlyHoveredPart != null && kIsWeb
                                ? _controller.currentlyHoveredPart
                                : null,
                        selectedParts: _controller.parts
                            .where(
                              (part) => widget.selectedParts.contains(part.id),
                            )
                            .toList(),
                        highlightColor: widget.highlightColor,
                        highlightStrokeWeight: widget.highlightStrokeWeight,
                        highlightStrokeColor: widget.highlightStrokeColor,
                        hoverColor: widget.hoverColor,
                        hoverStrokeWeight: widget.hoverStrokeWeight,
                        hoverStrokeColor: widget.hoverStrokeColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        return Stack(
          children: [
            child,
            if (_isSelecting &&
                _startSelection != null &&
                _endSelection != null &&
                widget.multiSelect) ...[
              CustomPaint(
                painter: SelectionRectPainter(
                  rect: _getSelectionRect(),
                ),
              ),
            ],
            _buildTooltip(currentPositonDetails),
          ],
        );
      }),
    );
  }

  void _singleSelectTapDown(TapDownDetails event) {
    Matrix4 matrix = _controller.transformationController.value;
    Matrix4 inverseMatrix = Matrix4.inverted(matrix);

    // Get the current transformation values from inverse matrix
    Vector3 currentTranslation = inverseMatrix.getTranslation();
    double currentScaleFactor = inverseMatrix.getMaxScaleOnAxis();

    double moveXtoPlanTopLeft =
        event.localPosition.dx - translateX * scaleX / currentScaleFactor;
    double moveYtoPlanTopLeft =
        event.localPosition.dy - translateY * scaleY / currentScaleFactor;

    double localX =
        (moveXtoPlanTopLeft + currentTranslation.x / currentScaleFactor);
    double localY =
        (moveYtoPlanTopLeft + currentTranslation.y / currentScaleFactor);

    Offset localPosition = Offset(localX, localY);

    for (var part in _controller.parts) {
      if (part.partType != SvgPartType.room) continue;
      if (part.scaledRect != null) {
        final scaledRect = part.scaledRect!;
        if (scaledRect.contains(localPosition) && part.id != null) {
          widget.onSinglePartSelected(part);
          _controller.currentlyHoveredPart = part;
          setState(() {});
          break;
        } else {
          _controller.currentlyHoveredPart = null;
          setState(() {});
        }
      }
    }
  }

  void _multiSelectTapDown(details) {
    if (!widget.multiSelect) return;
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
    Vector3 currentTranslation =
        _controller.transformationController.value.getTranslation();
    double currentScaleFactor =
        _controller.transformationController.value.getMaxScaleOnAxis();

    double moveLefttoPlanTopLeft = selectionRect.left - translateX * scaleX;
    double moveToptoPlanTopLeft = selectionRect.top - translateY * scaleY;

    double addTransTranslationToLeft =
        moveLefttoPlanTopLeft - currentTranslation.x;
    double addTranTranslationToTop =
        moveToptoPlanTopLeft - currentTranslation.y;

    Offset start = Offset(
      addTransTranslationToLeft,
      addTranTranslationToTop,
    );

    double moveRighttoPlanTopLeft = selectionRect.right - translateX * scaleX;
    double moveBottomtoPlanTopLeft = selectionRect.bottom - translateY * scaleY;

    double addTransTranslationToRight =
        moveRighttoPlanTopLeft - currentTranslation.x;
    double addTranTranslationToBottom =
        moveBottomtoPlanTopLeft - currentTranslation.y;

    Offset end = Offset(
      addTransTranslationToRight,
      addTranTranslationToBottom,
    );

    Rect newRect = Rect.fromPoints(start, end);

    List<SvgPart> selected = [];
    for (var part in _controller.parts) {
      if (part.partType != SvgPartType.room) continue;
      final path = part.parsedPath;
      final bounds = path.getBounds();
      final scaledRect = Rect.fromPoints(
        Offset(bounds.left * scaleX * currentScaleFactor,
            bounds.top * scaleY * currentScaleFactor),
        Offset(bounds.right * scaleX * currentScaleFactor,
            bounds.bottom * scaleY * currentScaleFactor),
      );
      if (scaledRect.overlaps(newRect)) {
        selected.add(part);
      }
    }
    setState(() {
      _selectedParts = selected;
    });
    widget.onMultiPartsSelected(
        _selectedParts.whereOrEmpty((element) => element.id != null).toList());
  }

  void _handleFit() {
    switch (widget.fit) {
      case BoxFit.contain:
        if (scaleY > scaleX) {
          scaleY = scaleX;
        } else if (scaleX > scaleY) {
          scaleX = scaleY;
        }
        break;
      case BoxFit.cover:
        final double biggerScale = math.max(scaleX, scaleY);
        scaleX = biggerScale;
        scaleY = biggerScale;
        break;
      case BoxFit.fill:
        if (maxWidth > maxHeight) {
          if (scaleY > scaleX) {
            scaleY = scaleX;
          }
        } else {
          if (scaleX > scaleY) {
            scaleX = scaleY;
          }
        }
        break;
      case BoxFit.fitWidth:
        scaleY = scaleX;
        break;
      case BoxFit.fitHeight:
        scaleX = scaleY;
        break;
      case BoxFit.scaleDown:
        if (scaleY > 1.0) {
          scaleY = 1.0;
        }
        if (scaleX > 1.0) {
          scaleX = 1.0;
        }
      default:
        break;
    }
  }

  _buildTooltip(TapDownDetails? currentPositonDetails) {
    // Check if the currently hovered part is not null
    if (_controller.currentlyHoveredPart == null) return Container();
    // Check if the current position details are not null
    if (currentPositonDetails == null) return Container();
    // Check if current position details is at the top side of the screen
    bool isTop = currentPositonDetails.localPosition.dy < imageHeight / 2;
    bool isLeft = currentPositonDetails.localPosition.dx < imageWidth / 2;

    // calculate the position of the tooltip
    double tooltipTop = isTop
        ? currentPositonDetails.globalPosition.dy + 30
        : currentPositonDetails.globalPosition.dy - 300;
    double tooltipLeft = isLeft
        ? currentPositonDetails.globalPosition.dx + 60
        : currentPositonDetails.globalPosition.dx - 60;

    Widget child = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.tooltipBackgroundColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        "Salle: ${_controller.currentlyHoveredPart!.name}"
        "\n\nGlobal Position: ${currentPositonDetails.localPosition.dx}, ${currentPositonDetails.localPosition.dy}"
        "\n\nLocal Position: ${currentPositonDetails.localPosition.dx}, ${currentPositonDetails.localPosition.dy}"
        "\n\n\nRect: ${_controller.currentlyHoveredPart!.scaledRect}",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );

    if (!isTop) {
      return Positioned(
        top: tooltipTop,
        left: tooltipLeft,
        child: child,
      );
    }

    return Positioned(
      top: tooltipTop,
      left: tooltipLeft,
      child: child,
    );
  }

// SvgPart parseElementToSvgPart(XmlElement element, String type) {
//   String? id = element.getAttribute('id');
//   if (id == "null" || id == null || id.isEmpty) {
//     id = null;
//   }
//   Color fillColor = widget.fillColor ??
//       convertColorToHex(
//         element.getAttribute('fill'),
//         noneColor: widget.backgroundColor,
//       );
//   if (fillColor != Colors.transparent && id != null) {
//     fillColor = fillColor.withOpacity(widget.fillOpacity);
//   }
//   Color strokeColor = convertColorToHex(
//     element.getAttribute('stroke'),
//     noneColor: widget.backgroundColor,
//   );
//   if (strokeColor != widget.backgroundColor && widget.borderColor != null) {
//     strokeColor = widget.borderColor!;
//   }
//   final double strokeWidth =
//       double.parse(element.getAttribute('stroke-width') ?? '2');
//   final String name = element.getAttribute('aria-label') ?? '';
//
//   String path;
//   switch (type) {
//     case 'rect':
//       final x = element.getAttribute('x') ?? '0';
//       final y = element.getAttribute('y') ?? '0';
//       final width = element.getAttribute('width') ?? '0';
//       final height = element.getAttribute('height') ?? '0';
//       path = 'M$x,$y h$width v$height h-$width Z';
//       break;
//     case 'polygon':
//       final points = element.getAttribute('points') ?? '';
//       path =
//           'M${points.split(' ').map((e) => e.replaceAll(',', ' ')).join(' L')} Z';
//       break;
//       final pointList =
//           points.split(RegExp(r'[\s,]+')).where((s) => s.isNotEmpty).toList();
//       if (pointList.length % 2 != 0) {
//         path = '';
//       } else {
//         path =
//             'M${pointList.asMap().entries.map((e) => '${e.value}${e.key % 2 == 0 ? ',' : ' '}').join()} Z';
//       }
//       break;
//     case 'polyline':
//       final points = element.getAttribute('points') ?? '';
//       final pointList =
//           points.split(RegExp(r'[\s,]+')).where((s) => s.isNotEmpty).toList();
//       if (pointList.length % 2 != 0) {
//         path = '';
//       } else {
//         path =
//             'M${pointList.asMap().entries.map((e) => '${e.value}${e.key % 2 == 0 ? ',' : ' '}').join()}';
//       }
//       break;
//     case 'line':
//       final x1 = element.getAttribute('x1') ?? '0';
//       final y1 = element.getAttribute('y1') ?? '0';
//       final x2 = element.getAttribute('x2') ?? '0';
//       final y2 = element.getAttribute('y2') ?? '0';
//       path = 'M$x1,$y1 L$x2,$y2';
//       break;
//     case 'circle':
//       final cx = double.tryParse(element.getAttribute('cx') ?? '0') ?? 0;
//       final cy = double.tryParse(element.getAttribute('cy') ?? '0') ?? 0;
//       final r = double.tryParse(element.getAttribute('r') ?? '0') ?? 0;
//       path =
//           'M${cx + r},$cy A$r,$r 0 1,1 ${cx - r},$cy A$r,$r 0 1,1 ${cx + r},$cy';
//       break;
//     case 'ellipse':
//       final cx = double.tryParse(element.getAttribute('cx') ?? '0') ?? 0;
//       final cy = double.tryParse(element.getAttribute('cy') ?? '0') ?? 0;
//       final rx = double.tryParse(element.getAttribute('rx') ?? '0') ?? 0;
//       final ry = double.tryParse(element.getAttribute('ry') ?? '0') ?? 0;
//       path =
//           'M${cx + rx},$cy A$rx,$ry 0 1,1 ${cx - rx},$cy A$rx,$ry 0 1,1 ${cx + rx},$cy';
//       break;
//     case 'path':
//       path = element.getAttribute('d') ?? '';
//       break;
//     default:
//       path = '';
//   }
//
//   return SvgPart(
//     id: id ?? (parts.isEmpty || ['rect', 'polygon', 'path'].contains(type) == false ? null : path),
//     path: path,
//     fillColor: fillColor,
//     strokeColor: strokeColor,
//     strokeWidth: strokeWidth,
//     name: name,
//     type: type,
//   );
// }
//
// Future<List<SvgPart>> loadSvgImage({required String svgImage}) async {
//   String generalString = await rootBundle.loadString(svgImage);
//
//   XmlDocument document = XmlDocument.parse(generalString);
//
//   canvasSize = Size(
//     double.parse(document.rootElement.getAttribute('width') ?? '3000'),
//     double.parse(document.rootElement.getAttribute('height') ?? '2250'),
//   );
//
//   // Combine queries to minimize DOM parsing time
//
//   // Handle <rect> elements
//   document.findAllElements('rect').forEach(
//       (element) => parts.add(parseElementToSvgPart(element, 'rect')));
//   // Handle <polygon> elements
//   document.findAllElements('polygon').forEach(
//       (element) => parts.add(parseElementToSvgPart(element, 'polygon')));
//   // Handle <polyline> elements
//   document.findAllElements('polyline').forEach(
//       (element) => parts.add(parseElementToSvgPart(element, 'polyline')));
//   // Handle <line> elements
//   document.findAllElements('line').forEach(
//       (element) => parts.add(parseElementToSvgPart(element, 'line')));
//   // Handle <circle> elements
//   document.findAllElements('circle').forEach(
//       (element) => parts.add(parseElementToSvgPart(element, 'circle')));
//   // Handle <ellipse> elements
//   document.findAllElements('ellipse').forEach(
//       (element) => parts.add(parseElementToSvgPart(element, 'ellipse')));
//   // Handle <path> elements
//   document.findAllElements('path').forEach(
//       (element) => parts.add(parseElementToSvgPart(element, 'path')));
//
//   return parts;
// }

  void _displayTooltip(event) {
    Matrix4 matrix = _controller.transformationController.value;
    Matrix4 inverseMatrix = Matrix4.inverted(matrix);

    // Get the current transformation values from inverse matrix
    Vector3 currentTranslation = inverseMatrix.getTranslation();
    double currentScaleFactor = inverseMatrix.getMaxScaleOnAxis();

    double moveXtoPlanTopLeft =
        event.localPosition.dx - translateX * scaleX / currentScaleFactor;
    double moveYtoPlanTopLeft =
        event.localPosition.dy - translateY * scaleY / currentScaleFactor;

    double localX =
        (moveXtoPlanTopLeft + currentTranslation.x / currentScaleFactor);
    double localY =
        (moveYtoPlanTopLeft + currentTranslation.y / currentScaleFactor);

    Offset localPosition = Offset(localX, localY);

    currentPositonDetails = TapDownDetails(
      globalPosition: event.localPosition,
      localPosition: localPosition,
    );

    for (var part in _controller.parts) {
      if (part.partType != SvgPartType.room) continue;
      if (part.scaledRect != null) {
        final scaledRect = part.scaledRect!;
        if (scaledRect.contains(localPosition) && part.id != null) {
          _controller.currentlyHoveredPart = part;
          setState(() {});
          break;
        } else {
          _controller.currentlyHoveredPart = null;
          setState(() {});
        }
      }
    }
  }
}

class SvgPathPainter extends CustomPainter {
  final List<SvgPart> parts;
  final List<SvgPart> selectedParts;
  final SvgPart? hoveredPart;
  final Color highlightColor;
  final Color hoverColor;
  final double highlightStrokeWeight;
  final double hoverStrokeWeight;
  final Color? highlightStrokeColor;
  final Color? hoverStrokeColor;

  SvgPathPainter({
    required this.parts,
    this.selectedParts = const [],
    this.hoveredPart,
    required this.highlightColor,
    required this.hoverColor,
    required this.highlightStrokeWeight,
    required this.hoverStrokeWeight,
    this.highlightStrokeColor,
    this.hoverStrokeColor,
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
        ..color = selectedParts.contains(part)
            ? (highlightStrokeColor ?? part.strokeColor)
            : part.strokeColor;

      final hoverStrokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hoverStrokeWeight
        ..color = hoverStrokeColor ?? part.strokeColor;

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = selectedParts.isEmpty
            ? part.fillColor
            : (selectedParts.contains(part) ? highlightColor : part.fillColor);

      final hoveredPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = hoverColor.withOpacity(0.5);

      try {
        final path = part.parsedPath;
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, strokePaint);
        if (hoveredPart != null && hoveredPart == part) {
          canvas.drawPath(path, hoveredPaint);
          canvas.drawPath(path, hoverStrokePaint);
        }
      } catch (e) {}
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
