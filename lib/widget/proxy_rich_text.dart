import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/markdown_generator.dart';

///use [ProxyRichText] to give `textScaleFactor` a default value
class ProxyRichText extends StatelessWidget {
  final InlineSpan textSpan;
  final RichTextBuilder? richTextBuilder;

  const ProxyRichText(
    this.textSpan, {
    Key? key,
    this.richTextBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (richTextBuilder != null) {
      return richTextBuilder!.call(textSpan);
    }

    // This ensures drag-select includes newlines for code blocks. Without
    // injecting a newline, it is one contiguous block when copied. This
    // is due to complex issues with the Flutter selection system. See
    // https://github.com/flutter/flutter/issues/104548#issuecomment-2051481671
    return Text.rich(
      TextSpan(
        children: [
          textSpan,
          // Native won't show \r.
          // Web will show \r and \n.
          // Use \n and set font size and height to 0 to make it invisible.
          // Per https://github.com/flutter/flutter/issues/104548#issuecomment-2051481671
          const TextSpan(
            text: '\r',
            style: TextStyle(
              fontSize: 0,
              height: 0,
            ),
          ),
        ],
      ),
    );
  }
}
