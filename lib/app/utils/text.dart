import 'package:flutter/material.dart';
import 'package:html_to_text/html_to_text.dart';

String htmlToPlainText(BuildContext context, String html) =>
    htmlToTextSpan(context, html).toPlainText();
