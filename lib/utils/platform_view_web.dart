import 'dart:ui_web';

typedef PlatformViewFactory = dynamic Function(int viewId);

bool registerViewFactory(String viewTypeId, PlatformViewFactory factory) {
  // ignore: undefined_prefixed_name
  return platformViewRegistry.registerViewFactory(viewTypeId, factory);
}
