import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'utils.dart' show Max;

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(final BuildContext context) {
    return MaterialApp(
      title: 'Staggered Grid Demo',
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _rand = math.Random();
  final _numContainers = 40;
  final _containerMinHeight = 140;
  final _containerMaxHeight = 280;

  Widget _genContainer(final int idx) {
    final height = (_rand.nextInt(_containerMaxHeight - _containerMinHeight) +
            _containerMinHeight)
        .toDouble();
    final color = Color(_rand.nextInt(0xffffff) | 0xff000000);

    return Container(
      height: height,
      color: color.withOpacity(0.2),
      child: Center(
        child: Text(
          idx.toString(),
          style: TextStyle(
            fontSize: 32,
            color: color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: StaggeredGrid(
            numColumns: 3,
            outerPadding: const EdgeInsets.only(
              left: 30,
              right: 30,
              top: 30,
              bottom: 30,
            ),
            innerPadding: 10,
            children: List(_numContainers)
                .asMap()
                .entries
                .map((final entry) => _genContainer(entry.key))
                .toList(growable: false),
          ),
        ),
      ),
    );
  }
}

class StaggeredGrid extends MultiChildRenderObjectWidget {
  StaggeredGrid({
    Key key,
    @required this.numColumns,
    this.innerPadding = 0.0,
    this.outerPadding = const EdgeInsets.all(0.0),
    List<Widget> children = const <Widget>[],
  })  : assert(numColumns != null),
        super(key: key, children: children);

  final int numColumns;
  final double innerPadding;
  final EdgeInsets outerPadding;

  @override
  RenderStaggeredGrid createRenderObject(final BuildContext context) {
    return RenderStaggeredGrid(
      numColumns: numColumns,
      innerPadding: innerPadding,
      outerPadding: outerPadding,
    );
  }

  @override
  void updateRenderObject(
    final BuildContext context,
    final RenderStaggeredGrid renderObject,
  ) {
    renderObject
      ..numColumns = numColumns
      ..innerPadding = innerPadding
      ..outerPadding = outerPadding;
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('numColumns', numColumns));
    properties.add(DoubleProperty('innerPadding', innerPadding));
    properties.add(
      DiagnosticsProperty<EdgeInsets>('outerPadding', outerPadding),
    );
  }
}

class RenderStaggeredGrid extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, StaggeredGridParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, StaggeredGridParentData> {
  RenderStaggeredGrid({
    @required this.numColumns,
    @required this.innerPadding,
    @required this.outerPadding,
    List<RenderBox> children,
  })  : assert(numColumns != null),
        assert(innerPadding != null),
        assert(outerPadding != null) {
    addAll(children);
  }

  int numColumns;
  double innerPadding;
  EdgeInsets outerPadding;

  int get numRows {
    final count = getChildrenAsList().length;
    return (count / numColumns).ceil();
  }

  @override
  void setupParentData(final RenderBox child) {
    if (child.parentData is! StaggeredGridParentData) {
      child.parentData = StaggeredGridParentData();
    }
  }

  double _getIntrinsicHeight(double childSize(final RenderBox child)) {
    var idx = 0;
    final yOffsets = List<double>(numColumns)
        .map((_) => outerPadding.top)
        .toList(growable: false);
    final lastRowIdx = _getPointFromIdx(getChildrenAsList().length - 1).y;
    var child = firstChild;
    while (child != null) {
      final point = _getPointFromIdx(idx);
      yOffsets[point.x] += childSize(child);
      if (point.y < lastRowIdx) {
        yOffsets[point.x] += innerPadding;
      }
      final childParentData = child.parentData as StaggeredGridParentData;
      child = childParentData.nextSibling;
      ++idx;
    }
    return yOffsets.maxOrNull() + outerPadding.bottom;
  }

  double _getIntrinsicWidth(double childSize(final RenderBox child)) {
    var idx = 0;
    var xOffsets = List<double>(numRows).map((_) => outerPadding.left).toList(
          growable: false,
        );
    var child = firstChild;
    while (child != null) {
      final point = _getPointFromIdx(idx);
      xOffsets[point.y] += childSize(child);
      if (point.x < (numRows - 1)) {
        xOffsets[point.y] += innerPadding;
      }
      final childParentData = child.parentData as StaggeredGridParentData;
      child = childParentData.nextSibling;
      ++idx;
    }
    return xOffsets.maxOrNull() + outerPadding.right;
  }

  @override
  double computeMinIntrinsicWidth(final double height) {
    return _getIntrinsicWidth(
      (final child) => child.getMinIntrinsicWidth(height),
    );
  }

  @override
  double computeMaxIntrinsicWidth(final double height) {
    return _getIntrinsicWidth(
      (final child) => child.getMaxIntrinsicWidth(height),
    );
  }

  @override
  double computeMinIntrinsicHeight(final double width) {
    return _getIntrinsicHeight(
      (final child) => child.getMinIntrinsicHeight(width),
    );
  }

  @override
  double computeMaxIntrinsicHeight(final double width) {
    return _getIntrinsicHeight(
      (final child) => child.getMaxIntrinsicHeight(width),
    );
  }

  math.Point<int> _getPointFromIdx(final int idx) {
    final col = idx % numColumns;
    final row = (idx / numColumns).truncate();
    return math.Point(col, row);
  }

  @override
  void performLayout() {
    if (childCount == 0) {
      size = constraints.biggest;
      assert(size.isFinite);
      return;
    }

    final newConstraints = constraints.tighten(
      width: constraints.maxWidth - (outerPadding.left + outerPadding.right),
      height: constraints.maxHeight - (outerPadding.top + outerPadding.bottom),
    );
    final viableWidth =
        newConstraints.maxWidth - (innerPadding * (numColumns - 1));

    var child = firstChild;
    var idx = 0;
    var xOffset = outerPadding.left;
    final yOffsets = List<double>(numColumns)
        .map((_) => outerPadding.top)
        .toList(growable: false);
    final lastRowIdx = _getPointFromIdx(getChildrenAsList().length - 1).y;
    while (child != null) {
      final point = _getPointFromIdx(idx);
      final childParentData = child.parentData as StaggeredGridParentData;
      final childWidth = viableWidth / numColumns;

      child.layout(
        BoxConstraints.tightFor(width: childWidth),
        parentUsesSize: true,
      );
      if (point.x == 0) {
        xOffset = outerPadding.left;
      }
      childParentData.offset = Offset(xOffset, yOffsets[point.x]);
      xOffset += childWidth + innerPadding;
      yOffsets[point.x] +=
          child.size.height + (point.y == lastRowIdx ? 0.0 : innerPadding);

      child = childParentData.nextSibling;
      ++idx;
    }

    final maxHeight = yOffsets.maxOrNull();
    size = Size(
      constraints.maxWidth - outerPadding.right,
      maxHeight + outerPadding.bottom,
    );
  }

  @override
  void paint(final PaintingContext context, final Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(
    final BoxHitTestResult result, {
    @required Offset position,
  }) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('numColumns', numColumns));
    properties.add(DoubleProperty('innerPadding', innerPadding));
    properties.add(
      DiagnosticsProperty<EdgeInsets>('outerPadding', outerPadding),
    );
  }
}

class StaggeredGridParentData extends ContainerBoxParentData<RenderBox> {}
