# GETIN Stripe Flutter compatibility shim

Source: `stripe_platform_interface` 11.5.0, copied from the package resolved by
`flutter pub get` on the GETIN Customer project.

Reason: this GETIN project currently uses an older Flutter framework whose
`dart:ui Color` exposes the integer `red`, `green`, `blue`, and `alpha` getters,
while stripe_platform_interface 11.5.0 uses the newer fractional `r`, `g`, `b`,
and `a` getters. The upstream flutter_stripe changelog later documented an
older-Flutter compatibility correction after 11.5.0.

Local change: only `lib/src/models/color.dart` is adjusted to generate the same
AARRGGBB hex value from the older integer component getters. No Stripe payment,
PaymentSheet, card-brand filtering, native Android/iOS, or API behavior is
changed.

Do not edit this vendored package except when intentionally upgrading Stripe or
the GETIN Flutter toolchain.
