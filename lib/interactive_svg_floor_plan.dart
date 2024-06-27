library interactive_svg_floor_plan;
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

class InteractiveSVGFloorPlan extends StatefulWidget {
  final String plan;

  const InteractiveSVGFloorPlan({super.key, required this.plan});

  @override
  State<InteractiveSVGFloorPlan> createState() => _InteractiveSVGFloorPlanState();
}

class _InteractiveSVGFloorPlanState extends State<InteractiveSVGFloorPlan> {
  List<SvgPart> parts = [];
  SvgPart? currentPart;
  Size canvasSize = const Size(3000, 2250); // Default canvas size (3000x2250

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      parts = await loadSvgImage(svgImage: widget.plan);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: LayoutBuilder(builder: (context, constraints) {
        final double scaleX = constraints.maxWidth / canvasSize.width;
        final double scaleY = constraints.maxHeight / canvasSize.height;
        // return Transform.scale(
        //   scale: scale,
        //   child: CustomPaint(
        //     painter: SvgPathPainter(parts: parts, currentPart: currentPart),
        //   ),
        // );
        return GestureDetector(
          onTapDown: (details) {
            log('Tapped down');
            log("Position: ${details.localPosition}");
            // scale the local position to the original size
            final localPosition = Offset(
              details.localPosition.dx / scaleX,
              details.localPosition.dy / scaleY,
            );
            log("Local position: $localPosition");

            bool isPartSelected = false;
            for (var part in parts) {
              final path = parseSvgPathData(part.path);
              if (path.contains(localPosition) && part.id != null) {
                isPartSelected = true;
                onPartSelected(part);
                break;
              }
            }
            if (!isPartSelected) {
              currentPart = null;
              setState(() {});
            }
          },
          child: Container(
            height: constraints.maxHeight,
            width: constraints.maxWidth,
            color: Colors.green,
            child: Transform(
              transform: Matrix4.identity()..scale(scaleX, scaleY),
              child: CustomPaint(
                painter:
                SvgPathPainter(parts: parts, currentPart: currentPart),
              ),
            ),
          ),
        );
      }),
    );
  }

  void onPartSelected(SvgPart part) {
    setState(() {
      currentPart = part;
      log('Selected part: ${part.toString()}');
    });
  }

  Future<List<SvgPart>> loadSvgImage({required String svgImage}) async {
    List<SvgPart> parts = [];
    String generalString = await rootBundle.loadString(svgImage);

    XmlDocument document = XmlDocument.parse(generalString);

    canvasSize = Size(
      double.parse(document.rootElement.getAttribute('width') ?? '3000'),
      double.parse(document.rootElement.getAttribute('height') ?? '2250'),
    );

    // Handle <rect> elements
    document.findAllElements('rect').forEach((element) {
      String? id = element.getAttribute('id');
      if (id == "null" || id == null || id.isEmpty) {
        id = null;
      }
      final x = element.getAttribute('x') ?? '0';
      final y = element.getAttribute('y') ?? '0';
      final width = element.getAttribute('width') ?? '0';
      final height = element.getAttribute('height') ?? '0';
      final path = 'M$x,$y h$width v$height h-$width Z';
      final fillColor =
      convertColorToHex(element.getAttribute('fill').toString());
      final strokeColor =
      convertColorToHex(element.getAttribute('stroke').toString());
      final name = element.getAttribute('aria-label') ?? '';
      final strokeWidth = double.parse(element.getAttribute('stroke-width') ?? '2');

      parts.add(SvgPart(
          id: id,
          path: path,
          fillColor: fillColor,
          strokeColor: strokeColor,
          strokeWidth: strokeWidth,
          name: name));
    });

    // Handle <polygon> elements
    document.findAllElements('polygon').forEach((element) {
      final id = element.getAttribute('id') ?? '';
      final points = element.getAttribute('points') ?? '';
      final path = 'M${points.replaceAll(' ', ' L')} Z';
      final fillColor =
      convertColorToHex(element.getAttribute('fill').toString());
      final strokeColor =
      convertColorToHex(element.getAttribute('stroke').toString());
      final name = element.getAttribute('aria-label') ?? '';
      final strokeWidth = double.parse(element.getAttribute('stroke-width') ?? '2');

      parts.add(SvgPart(
          id: id,
          path: path,
          fillColor: fillColor,
          strokeColor: strokeColor,
          strokeWidth: strokeWidth,
          name: name));
    });

    // Handle <line> elements
    document.findAllElements('line').forEach((element) {
      final id = element.getAttribute('id') ?? '';
      final x1 = element.getAttribute('x1') ?? '0';
      final y1 = element.getAttribute('y1') ?? '0';
      final x2 = element.getAttribute('x2') ?? '0';
      final y2 = element.getAttribute('y2') ?? '0';
      final path = 'M$x1,$y1 L$x2,$y2';
      final fillColor =
      convertColorToHex(element.getAttribute('fill').toString());
      final strokeColor =
      convertColorToHex(element.getAttribute('stroke').toString());
      final name = element.getAttribute('aria-label') ?? '';
      final strokeWidth = double.parse(element.getAttribute('stroke-width') ?? '2');

      parts.add(SvgPart(
          id: id,
          path: path,
          fillColor: fillColor,
          strokeColor: strokeColor,
          strokeWidth: strokeWidth,
          name: name));
    });

    return parts;
  }
}

class SvgPart {
  final String? id;
  final String path;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final String name;

  SvgPart({
    required this.id,
    required this.path,
    required this.fillColor,
    required this.strokeColor,
    this.strokeWidth = 2.0,
    required this.name,
  });

  @override
  String toString() {
    return 'SvgPart{id: $id, path: $path, fillColor: $fillColor, strokeColor: $strokeColor, name: $name}';
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

Color convertColorToHex(String color) {
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

  return Colors.transparent; // Default to black if color format is unknown
}

class SvgPathPainter extends CustomPainter {
  final List<SvgPart> parts;
  final SvgPart? currentPart;

  SvgPathPainter({
    required this.parts,
    this.currentPart,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var part in parts) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentPart == null
            ? part.strokeWidth
            : (currentPart?.id == part.id ? part.strokeWidth * 2.0 : part.strokeWidth)
        ..color = part.strokeColor;

      final path = parseSvgPathData(part.path);
      canvas.drawPath(path, paint);

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = currentPart == null
            ? part.fillColor
            : (currentPart?.id == part.id ? Colors.red : part.fillColor.withOpacity(part.fillColor == Colors.transparent ? 0 : .5));

      canvas.drawPath(path, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
