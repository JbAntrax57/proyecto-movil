import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

const supportedLocales = [Locale('es'), Locale('en')];
const localizationsDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
]; 