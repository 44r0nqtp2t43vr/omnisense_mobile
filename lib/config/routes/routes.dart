import 'package:flutter/material.dart';
import 'package:omnisense_mobile/features/acc_receive/presentation/pages/acc_receive/acc_receive_screen.dart';

class AppRoutes {
  static Route onGenerateRoutes(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _materialRoute(const AccReceiveScreen());

      case '/AccReceive':
        return _materialRoute(const AccReceiveScreen());

      default:
        return _materialRoute(const AccReceiveScreen());
    }
  }

  static Route<dynamic> _materialRoute(Widget view) {
    return MaterialPageRoute(builder: (_) => view, maintainState: false);
  }
}
