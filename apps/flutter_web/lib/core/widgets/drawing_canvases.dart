import 'package:flutter/material.dart';
import '../theme/theme.dart';

enum CanvasTool { select, rectangle, circle, arrow, northArrow, text }

class CanvasElement {
  final CanvasTool type;
  final Offset start;
  final Offset end;
  final String text;
  final Color color;

  CanvasElement({
    required this.type,
    required this.start,
    required this.end,
    this.text = '',
    this.color = VianTheme.primaryGold,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'startX': start.dx,
    'startY': start.dy,
    'endX': end.dx,
    'endY': end.dy,
    'text': text,
  };

  factory CanvasElement.fromJson(Map<String, dynamic> json) {
    return CanvasElement(
      type: CanvasTool.values.firstWhere((e) => e.name == json['type'], orElse: () => CanvasTool.rectangle),
      start: Offset((json['startX'] as num).toDouble(), (json['startY'] as num).toDouble()),
      end: Offset((json['endX'] as num).toDouble(), (json['endY'] as num).toDouble()),
      text: json['text'] ?? '',
    );
  }
}

class SiteLayoutCanvas extends StatefulWidget {
  final List<CanvasElement> elements;
  final ValueChanged<List<CanvasElement>> onChanged;

  const SiteLayoutCanvas({
    Key? key,
    required this.elements,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<SiteLayoutCanvas> createState() => _SiteLayoutCanvasState();
}

class _SiteLayoutCanvasState extends State<SiteLayoutCanvas> {
  CanvasTool _currentTool = CanvasTool.rectangle;
  Offset? _startPos;
  Offset? _currentPos;
  final List<List<CanvasElement>> _undoHistory = [];
  final List<List<CanvasElement>> _redoHistory = [];

  void _saveToHistory() {
    _undoHistory.add(List.from(widget.elements));
    _redoHistory.clear();
    if (_undoHistory.length > 20) {
      _undoHistory.removeAt(0);
    }
  }

  void _undo() {
    if (_undoHistory.isNotEmpty) {
      setState(() {
        _redoHistory.add(List.from(widget.elements));
        final previous = _undoHistory.removeLast();
        widget.onChanged(previous);
      });
    }
  }

  void _redo() {
    if (_redoHistory.isNotEmpty) {
      setState(() {
        _undoHistory.add(List.from(widget.elements));
        final next = _redoHistory.removeLast();
        widget.onChanged(next);
      });
    }
  }

  void _clear() {
    if (widget.elements.isNotEmpty) {
      _saveToHistory();
      widget.onChanged([]);
    }
  }

  Future<void> _addTextElement(Offset pos) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E26),
        title: const Text('Add Dimension/Label Text', style: TextStyle(color: VianTheme.primaryGold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. 40ft road, Site boundary 30x50'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (text != null && text.trim().isNotEmpty) {
      _saveToHistory();
      final updated = List<CanvasElement>.from(widget.elements)
        ..add(CanvasElement(
          type: CanvasTool.text,
          start: pos,
          end: pos,
          text: text.trim(),
        ));
      widget.onChanged(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Canvas Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E26),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.start,
            children: [
              _buildToolButton(CanvasTool.rectangle, Icons.crop_square, 'Rect'),
              _buildToolButton(CanvasTool.circle, Icons.circle_outlined, 'Circle'),
              _buildToolButton(CanvasTool.arrow, Icons.trending_flat, 'Arrow'),
              _buildToolButton(CanvasTool.northArrow, Icons.navigation_outlined, 'North'),
              _buildToolButton(CanvasTool.text, Icons.text_fields, 'Text'),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.undo, color: Colors.white, size: 20),
                onPressed: _undoHistory.isNotEmpty ? _undo : null,
                tooltip: 'Undo',
              ),
              IconButton(
                icon: const Icon(Icons.redo, color: Colors.white, size: 20),
                onPressed: _redoHistory.isNotEmpty ? _redo : null,
                tooltip: 'Redo',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: VianTheme.danger, size: 20),
                onPressed: _clear,
                tooltip: 'Clear Layout',
              ),
            ],
          ),
        ),
        // Canvas Painting Board
        GestureDetector(
          onPanStart: (details) {
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final localPos = renderBox.globalToLocal(details.globalPosition);
            // Adjust for toolbar offset
            final pos = Offset(localPos.dx, localPos.dy - 40); // estimate toolbar height

            if (_currentTool == CanvasTool.text) {
              _addTextElement(pos);
            } else if (_currentTool == CanvasTool.northArrow) {
              _saveToHistory();
              final updated = List<CanvasElement>.from(widget.elements)
                ..add(CanvasElement(
                  type: CanvasTool.northArrow,
                  start: pos,
                  end: pos,
                ));
              widget.onChanged(updated);
            } else {
              setState(() {
                _startPos = pos;
                _currentPos = pos;
              });
            }
          },
          onPanUpdate: (details) {
            if (_startPos == null) return;
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final localPos = renderBox.globalToLocal(details.globalPosition);
            setState(() {
              _currentPos = Offset(localPos.dx, localPos.dy - 40);
            });
          },
          onPanEnd: (details) {
            if (_startPos != null && _currentPos != null) {
              _saveToHistory();
              final updated = List<CanvasElement>.from(widget.elements)
                ..add(CanvasElement(
                  type: _currentTool,
                  start: _startPos!,
                  end: _currentPos!,
                ));
              widget.onChanged(updated);
            }
            setState(() {
              _startPos = null;
              _currentPos = null;
            });
          },
          child: Container(
            height: 350,
            width: double.infinity,
            color: const Color(0xFF13131A),
            child: ClipRect(
              child: CustomPaint(
                painter: SiteLayoutPainter(
                  widget.elements,
                  (_startPos != null && _currentPos != null)
                      ? CanvasElement(type: _currentTool, start: _startPos!, end: _currentPos!)
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolButton(CanvasTool tool, IconData icon, String label) {
    final active = _currentTool == tool;
    return InkWell(
      onTap: () => setState(() => _currentTool = tool),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? VianTheme.primaryGold : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: active ? VianTheme.goldBorder : Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? Colors.black : Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.black : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SiteLayoutPainter extends CustomPainter {
  final List<CanvasElement> elements;
  final CanvasElement? currentElement;

  SiteLayoutPainter(this.elements, this.currentElement);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background grid lines
    final gridPaint = Paint()
      ..color = const Color(0x1370707C)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final borderPaint = Paint()
      ..color = const Color(0x22F5A623)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Offset.zero & size, borderPaint);

    // Paint historical elements
    for (var el in elements) {
      _drawElement(canvas, el);
    }

    // Paint active dragging element
    if (currentElement != null) {
      _drawElement(canvas, currentElement!);
    }
  }

  void _drawElement(Canvas canvas, CanvasElement el) {
    final paint = Paint()
      ..color = el.color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    switch (el.type) {
      case CanvasTool.rectangle:
        canvas.drawRect(Rect.fromPoints(el.start, el.end), paint);
        break;
      case CanvasTool.circle:
        double r = (el.end - el.start).distance;
        canvas.drawCircle(el.start, r, paint);
        break;
      case CanvasTool.arrow:
        _drawArrow(canvas, el.start, el.end, paint);
        break;
      case CanvasTool.northArrow:
        _drawNorthArrow(canvas, el.start, paint);
        break;
      case CanvasTool.text:
        _drawText(canvas, el.start, el.text, el.color);
        break;
      default:
        break;
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    final direction = end - start;
    if (direction.distance < 1.0) return;
    final unitDirection = direction / direction.distance;
    final normal = Offset(-unitDirection.dy, unitDirection.dx);

    const arrowHeadLength = 12.0;
    const arrowHeadWidth = 6.0;

    final leftPoint = end - unitDirection * arrowHeadLength + normal * arrowHeadWidth;
    final rightPoint = end - unitDirection * arrowHeadLength - normal * arrowHeadWidth;

    final fillPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(leftPoint.dx, leftPoint.dy)
      ..lineTo(rightPoint.dx, rightPoint.dy)
      ..close();
    canvas.drawPath(path, fillPaint);
  }

  void _drawNorthArrow(Canvas canvas, Offset pos, Paint paint) {
    final fillPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    canvas.drawLine(pos + const Offset(0, 15), pos - const Offset(0, 15), paint);
    final arrowPath = Path()
      ..moveTo(pos.dx, pos.dy - 15)
      ..lineTo(pos.dx - 5, pos.dy - 7)
      ..lineTo(pos.dx + 5, pos.dy - 7)
      ..close();
    canvas.drawPath(arrowPath, fillPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'N',
        style: TextStyle(color: paint.color, fontWeight: FontWeight.bold, fontSize: 13),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, pos - Offset(textPainter.width / 2, 30));
  }

  void _drawText(Canvas canvas, Offset pos, String text, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500, backgroundColor: const Color(0xDD000000)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant SiteLayoutPainter oldDelegate) => true;
}

class SketchStroke {
  final List<Offset> points;
  final Color color;
  final double width;

  SketchStroke({
    required this.points,
    this.color = VianTheme.primaryGold,
    this.width = 3.0,
  });

  Map<String, dynamic> toJson() => {
    'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
    'color': color.value,
    'width': width,
  };

  factory SketchStroke.fromJson(Map<String, dynamic> json) {
    return SketchStroke(
      points: (json['points'] as List).map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble())).toList(),
      color: Color(json['color'] as int),
      width: (json['width'] as num).toDouble(),
    );
  }
}

class ConceptSketchCanvas extends StatefulWidget {
  final List<SketchStroke> strokes;
  final ValueChanged<List<SketchStroke>> onChanged;

  const ConceptSketchCanvas({
    Key? key,
    required this.strokes,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<ConceptSketchCanvas> createState() => _ConceptSketchCanvasState();
}

class _ConceptSketchCanvasState extends State<ConceptSketchCanvas> {
  double _strokeWidth = 3.0;
  List<Offset>? _currentStroke;
  final List<List<SketchStroke>> _undoHistory = [];
  final List<List<SketchStroke>> _redoHistory = [];

  void _saveToHistory() {
    _undoHistory.add(List.from(widget.strokes));
    _redoHistory.clear();
    if (_undoHistory.length > 20) {
      _undoHistory.removeAt(0);
    }
  }

  void _undo() {
    if (_undoHistory.isNotEmpty) {
      setState(() {
        _redoHistory.add(List.from(widget.strokes));
        final previous = _undoHistory.removeLast();
        widget.onChanged(previous);
      });
    }
  }

  void _redo() {
    if (_redoHistory.isNotEmpty) {
      setState(() {
        _undoHistory.add(List.from(widget.strokes));
        final next = _redoHistory.removeLast();
        widget.onChanged(next);
      });
    }
  }

  void _clear() {
    if (widget.strokes.isNotEmpty) {
      _saveToHistory();
      widget.onChanged([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sketch Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E26),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
          ),
          child: Row(
            children: [
              const Icon(Icons.edit, color: VianTheme.primaryGold, size: 18),
              const SizedBox(width: 8),
              const Text('Brush Width:', style: TextStyle(fontSize: 12, color: Colors.white70)),
              _buildWidthButton(1.5, 'Thin'),
              _buildWidthButton(3.0, 'Medium'),
              _buildWidthButton(6.0, 'Thick'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.undo, color: Colors.white, size: 20),
                onPressed: _undoHistory.isNotEmpty ? _undo : null,
                tooltip: 'Undo',
              ),
              IconButton(
                icon: const Icon(Icons.redo, color: Colors.white, size: 20),
                onPressed: _redoHistory.isNotEmpty ? _redo : null,
                tooltip: 'Redo',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: VianTheme.danger, size: 20),
                onPressed: _clear,
                tooltip: 'Clear Sketch',
              ),
            ],
          ),
        ),
        // Painting Board
        GestureDetector(
          onPanStart: (details) {
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final localPos = renderBox.globalToLocal(details.globalPosition);
            final pos = Offset(localPos.dx, localPos.dy - 40); // offset estimate
            setState(() {
              _currentStroke = [pos];
            });
          },
          onPanUpdate: (details) {
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final localPos = renderBox.globalToLocal(details.globalPosition);
            final pos = Offset(localPos.dx, localPos.dy - 40);
            if (_currentStroke != null) {
              setState(() {
                _currentStroke!.add(pos);
              });
            }
          },
          onPanEnd: (details) {
            if (_currentStroke != null && _currentStroke!.isNotEmpty) {
              _saveToHistory();
              final updated = List<SketchStroke>.from(widget.strokes)
                ..add(SketchStroke(
                  points: _currentStroke!,
                  color: VianTheme.primaryGold,
                  width: _strokeWidth,
                ));
              widget.onChanged(updated);
            }
            setState(() {
              _currentStroke = null;
            });
          },
          child: Container(
            height: 350,
            width: double.infinity,
            color: const Color(0xFF13131A),
            child: ClipRect(
              child: CustomPaint(
                painter: ConceptSketchPainter(
                  widget.strokes,
                  _currentStroke,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWidthButton(double width, String label) {
    final active = _strokeWidth == width;
    return InkWell(
      onTap: () => setState(() => _strokeWidth = width),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? VianTheme.primaryGold : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: active ? VianTheme.goldBorder : Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class ConceptSketchPainter extends CustomPainter {
  final List<SketchStroke> strokes;
  final List<Offset>? currentStroke;

  ConceptSketchPainter(this.strokes, this.currentStroke);

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0x22F5A623)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Offset.zero & size, borderPaint);

    for (var stroke in strokes) {
      _drawStroke(canvas, stroke.points, stroke.color, stroke.width);
    }

    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!, VianTheme.primaryGold, 3.0);
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Color color, double width) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ConceptSketchPainter oldDelegate) => true;
}
