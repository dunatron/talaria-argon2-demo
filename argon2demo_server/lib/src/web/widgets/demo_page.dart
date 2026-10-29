import 'package:serverpod/serverpod.dart';

/// Tiny UI: PointyCastle / Native / Run both + dashboard deep link.
class DemoPageWidget extends TemplateWidget {
  DemoPageWidget({String? dashboardUrl}) : super(name: 'demo') {
    values = {
      'dashboardUrl': dashboardUrl ?? 'https://one.newtalaria.com',
      'served': DateTime.now().toIso8601String(),
    };
  }
}
