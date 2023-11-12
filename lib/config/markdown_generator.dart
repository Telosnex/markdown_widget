import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as m;

import '../widget/blocks/leaf/heading.dart';
import '../widget/span_node.dart';
import '../widget/widget_visitor.dart';
import 'configs.dart';
import 'toc.dart';

///use [MarkdownGenerator] to transform markdown data to [Widget] list, so you can render it by any type of [ListView]
class MarkdownGenerator {
  final Iterable<m.InlineSyntax> inlineSyntaxList;
  final Iterable<m.BlockSyntax> blockSyntaxList;
  final EdgeInsets linesMargin;
  final List<SpanNodeGeneratorWithTag> generators;
  final SpanNodeAcceptCallback? onNodeAccepted;
  final m.ExtensionSet? extensionSet;
  final TextNodeGenerator? textGenerator;
  final SpanNodeBuilder? onSpanNodeBuild;
  final List<m.Node>? cachedNodes;

  MarkdownGenerator({
    this.inlineSyntaxList = const [],
    this.blockSyntaxList = const [],
    this.linesMargin = const EdgeInsets.symmetric(vertical: 8),
    this.generators = const [],
    this.onNodeAccepted,
    this.extensionSet,
    this.textGenerator,
    this.onSpanNodeBuild,
    this.cachedNodes,
  });

  ///convert [data] to widgets
  ///[onTocList] can provider [Toc] list
  List<Widget> buildWidgets(String data,
      {ValueCallback<List<Toc>>? onTocList, MarkdownConfig? config}) {
    final List<m.Node> nodes;
    if (cachedNodes != null) {
      nodes = cachedNodes!;
    } else {
      nodes = m.Document(
        extensionSet: extensionSet ?? m.ExtensionSet.gitHubFlavored,
        encodeHtml: false,
        inlineSyntaxes: inlineSyntaxList,
        blockSyntaxes: blockSyntaxList,
      ).parseLines(data.split(RegExp(r'(\r?\n)|(\r?\t)|(\r)')));
    }
    final List<Toc> tocList = [];
    final mdConfig = config ?? MarkdownConfig.defaultConfig;
    final visitor = WidgetVisitor(
        config: mdConfig,
        generators: generators,
        textGenerator: textGenerator,
        onNodeAccepted: (node, index) {
          onNodeAccepted?.call(node, index);
          if (node is HeadingNode) {
            final listLength = tocList.length;
            tocList.add(
                Toc(node: node, widgetIndex: index, selfIndex: listLength));
          }
        });
    final spans = visitor.visit(nodes);
    onTocList?.call(tocList);
    final List<Widget> widgets = [];
    spans.forEach((span) {
      widgets.add(Padding(
        padding: linesMargin,
        child: Text.rich(onSpanNodeBuild?.call(span) ?? span.build()),
      ));
    });
    return widgets;
  }
}

typedef SpanNodeBuilder = TextSpan Function(SpanNode spanNode);
