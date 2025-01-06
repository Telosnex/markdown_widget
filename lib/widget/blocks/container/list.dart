import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../config/configs.dart';
import '../../inlines/input.dart';
import '../../proxy_rich_text.dart';
import '../../span_node.dart';
import '../../widget_visitor.dart';
import '../leaf/paragraph.dart';

///Tag [MarkdownTag.ol]、[MarkdownTag.ul]
///
/// ordered list and unordered widget
class UlOrOLNode extends ElementNode {
  final String tag;
  final ListConfig config;
  final Map<String, String> attribute;
  late int start;
  final WidgetVisitor visitor;

  UlOrOLNode(this.tag, this.attribute, this.config, this.visitor) {
    start = (int.tryParse(attribute['start'] ?? '') ?? 1) - 1;
  }

  @override
  void accept(SpanNode? node) {
    super.accept(node);
    if (node != null && node is ListNode) {
      node._index = start;
      start++;
    }
  }

  @override
  InlineSpan build() {
    return TextSpan(
      children: children.map((child) => child.build()).toList(),
    );
  }

  @override
  TextStyle? get style => parentStyle;
}

///Tag [MarkdownTag.li]
///
/// A list is a sequence of one or more list items of the same type.
/// The list items may be separated by any number of blank lines.
class ListNode extends ElementNode {
  final MarkdownConfig config;
  final WidgetVisitor visitor;

  ListNode(this.config, this.visitor);

  int _index = 0;

  int get index => _index;

  bool get isOrdered {
    final p = parent;
    return p != null && p is UlOrOLNode && p.tag == MarkdownTag.ol.name;
  }

  int get depth {
    int d = 0;
    SpanNode? p = parent;
    while (p != null) {
      p = p.parent;
      if (p != null && p is UlOrOLNode && _listTag.contains(p.tag)) d += 1;
    }
    return d;
  }

  @override
  InlineSpan build() {
    // Create the marker text with proper indentation
    final indent = '  ' * depth;
    final marker = isOrdered ? '${index + 1}. ' : '• ';
    final markerText = indent + marker;

    return TextSpan(
      children: [
        TextSpan(text: markerText, style: parentStyle),
        if (children.isNotEmpty) children.first.build(),
        const TextSpan(text: '\n'), 
        for (final child in children.skip(1)) ...[
          if (child is UlOrOLNode) const TextSpan(text: '\n'),
          child.build(),
        ],
      ],
    );
  }

  bool get isCheckbox {
    return children.isNotEmpty && children.first is InputNode;
  }

  @override
  TextStyle? get style => parentStyle;
}

///config class for list, tag: li
class ListConfig implements ContainerConfig {
  ///the value margin left for list children
  final double marginLeft;

  ///the value margin left bottom list children
  final double marginBottom;

  ///the marker widget for list
  final ListMarker? marker;

  const ListConfig({
    this.marginLeft = 32.0,
    this.marginBottom = 4.0,
    this.marker,
  });

  @nonVirtual
  @override
  String get tag => MarkdownTag.li.name;
}

///the function to get marker widget
typedef ListMarker = Widget? Function(bool isOrdered, int depth, int index);

///the default marker widget for unordered list
class _UlMarker extends StatelessWidget {
  final int depth;
  final Color? color;

  const _UlMarker({Key? key, this.depth = 0, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.textTheme.titleLarge?.color ?? Colors.black;
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 6,
        height: 6,
        decoration: get(depth % 3, c),
      ),
    );
  }

  BoxDecoration get(int depth, Color color) {
    if (depth == 0) {
      return BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      );
    } else if (depth == 1) {
      return BoxDecoration(
        border: Border.all(color: color),
        shape: BoxShape.circle,
      );
    }
    return BoxDecoration(color: color);
  }
}

///the default marker widget for ordered list
class _OlMarker extends StatelessWidget {
  final int depth;
  final int index;
  final Color? color;
  final PConfig config;

  const _OlMarker(
      {Key? key,
      this.depth = 0,
      this.color,
      this.index = 1,
      required this.config})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SelectionContainer.disabled(
        child: Text('${index + 1}.',
            style: config.textStyle.copyWith(color: color)));
  }
}

///get default marker for list
Widget getDefaultMarker(bool isOrdered, int depth, Color? color, int index,
    double paddingTop, MarkdownConfig config) {
  Widget marker;
  if (isOrdered) {
    marker = Container(
        alignment: Alignment.topRight,
        padding: EdgeInsets.only(right: 1),
        child: _OlMarker(
            depth: depth, index: index, color: color, config: config.p));
  } else {
    marker = Padding(
        padding: EdgeInsets.only(top: paddingTop - 1.5),
        child: _UlMarker(depth: depth, color: color));
  }
  return marker;
}

const _listTag = {'ul', 'ol'};
