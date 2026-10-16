import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:seelocals/app.dart';

void main() {
  // Real paths on web (`/e/123`) instead of `/#/e/123`.
  usePathUrlStrategy();
  runApp(const ProviderScope(child: SeeLocalsApp()));
}
