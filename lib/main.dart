import 'package:flutter/material.dart';
import 'package:omnisense_mobile/config/routes/routes.dart';
import 'package:omnisense_mobile/features/acc_receive/presentation/pages/acc_receive/acc_receive_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRoutes.onGenerateRoutes,
      home: const AccReceiveScreen(),
    );
  }
}
