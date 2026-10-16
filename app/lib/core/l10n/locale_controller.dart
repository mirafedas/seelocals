import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_controller.g.dart';

/// The locale chosen by the user; `null` follows the device locale.
// TODO(step-4): persist the choice in the user's profile.
@Riverpod(keepAlive: true)
class LocaleController extends _$LocaleController {
  @override
  Locale? build() => null;

  void select(Locale? locale) => state = locale;
}
