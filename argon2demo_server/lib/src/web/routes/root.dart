import 'package:argon2demo_server/src/cache_busting.dart';
import 'package:argon2demo_server/src/web/widgets/demo_page.dart';
import 'package:serverpod/serverpod.dart';

class RootRoute extends WidgetRoute {
  RootRoute({this.dashboardUrl})
      : super(cacheBustingConfig: cacheBustingConfig);

  final String? dashboardUrl;

  @override
  Future<TemplateWidget> build(Session session, Request request) async {
    return DemoPageWidget(dashboardUrl: dashboardUrl);
  }
}
