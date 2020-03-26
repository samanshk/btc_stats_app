import 'package:flutter/material.dart';
import 'package:dynamic_theme/dynamic_theme.dart';

import 'Home.dart';

void main() => runApp(MyApp());

// class MyApp extends StatelessWidget {
//   static var theme = Brightness.dark;
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'BTC Stats',
//       theme: ThemeData(
//         brightness: theme
//       ),
//       home: Home()
//     );
//   }
// }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new DynamicTheme(
      defaultBrightness: Brightness.light,
      data: (brightness) => new ThemeData(
        primarySwatch: Colors.deepOrange,
        brightness: brightness,
      ),
      themedWidgetBuilder: (context, theme) {
        return new MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          theme: theme,
          home: new Home(),
        );
      }
    );
  }
}