import 'package:flutter/material.dart';

import '../models/game_catalog.dart';

const ink = Color(0xFF17213F),
    primary = Color(0xFF6556E8),
    success = Color(0xFF169A75);
const muted = Color(0xFF737B95), background = Color(0xFFF5F6FB);
const gameColors = [
  Color(0xFF6656E8),
  Color(0xFF1886B7),
  Color(0xFFE98445),
  Color(0xFF278D79),
  Color(0xFFD16B90),
  Color(0xFF5575BF),
];
const abilityIcons = [
  Icons.psychology_rounded,
  Icons.center_focus_strong_rounded,
  Icons.bolt_rounded,
  Icons.extension_rounded,
  Icons.calculate_rounded,
  Icons.view_in_ar_rounded,
];
const visualColors = [
  Color(0xFF6656E8),
  Color(0xFFE04E59),
  Color(0xFF16866B),
  Color(0xFFB98908),
  Color(0xFF2184BA),
  Color(0xFFB9539F),
];
const colorNames = ['紫色', '红色', '绿色', '黄色', '蓝色', '粉色'];

Color categoryColor(Ability ability) => gameColors[ability.index];
IconData categoryIcon(Ability ability) => abilityIcons[ability.index];
IconData gameIcon(GameId id) => const [
  Icons.pin_rounded,
  Icons.location_searching_rounded,
  Icons.filter_none_rounded,
  Icons.gesture_rounded,
  Icons.grid_3x3_rounded,
  Icons.compare_rounded,
  Icons.manage_search_rounded,
  Icons.palette_outlined,
  Icons.bolt_rounded,
  Icons.ads_click_rounded,
  Icons.pan_tool_alt_rounded,
  Icons.music_note_rounded,
  Icons.trending_up_rounded,
  Icons.extension_rounded,
  Icons.rule_rounded,
  Icons.sort_rounded,
  Icons.calculate_rounded,
  Icons.functions_rounded,
  Icons.compare_arrows_rounded,
  Icons.apps_rounded,
  Icons.rotate_right_rounded,
  Icons.flip_rounded,
  Icons.widgets_rounded,
  Icons.route_rounded,
][id.index];

ThemeData trainingTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: primary),
  scaffoldBackgroundColor: background,
  appBarTheme: const AppBarTheme(
    backgroundColor: background,
    foregroundColor: ink,
    centerTitle: true,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(fontSize: 31, fontWeight: FontWeight.w800),
    headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16, height: 1.55),
    bodyMedium: TextStyle(fontSize: 14, height: 1.45),
  ).apply(bodyColor: ink, displayColor: ink),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  ),
);
