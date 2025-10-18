// lib/utils/app_route_observer.dart
import 'package:flutter/widgets.dart';

/// RouteObserver toàn cục để theo dõi việc vào/ra các màn hình.
/// Các widget cần biết khi được hiển thị lại có thể mixin RouteAware
/// và subscribe/unsubscribe với observer này.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
