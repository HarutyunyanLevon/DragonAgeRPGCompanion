/// Window widths (in logical pixels) where the layout changes shape.
const _tabletFromWidth = 600.0; // icon rail on the left
const _desktopFromWidth = 1000.0; // rail with labels

enum DeviceClass { phone, tablet, desktop }

DeviceClass deviceClassFor(double width) {
  if (width >= _desktopFromWidth) return DeviceClass.desktop;
  if (width >= _tabletFromWidth) return DeviceClass.tablet;
  return DeviceClass.phone;
}
