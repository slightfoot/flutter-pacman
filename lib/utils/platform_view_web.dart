import 'dart:ui' as ui;

typedef PlatformViewFactory = dynamic Function(int viewId);

bool registerViewFactory(String viewTypeId, PlatformViewFactory factory) {
  // ignore: undefined_prefixed_name
  return ui.platformViewRegistry.registerViewFactory(viewTypeId, factory) as bool;
}
