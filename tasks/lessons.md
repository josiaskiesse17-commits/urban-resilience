# Lessons

## TextEditingController + dialogs

- Never create a `TextEditingController` outside a dialog and `dispose()` it in the caller after `showDialog` returns.
- The dialog route can still rebuild (pop animation, or `Theme` / InheritedWidget updates) after the future completes — a disposed controller then crashes (`used after being disposed`) and corrupts the element tree (`_dependents.isEmpty`, wrong build scope).
- Own controllers in a `StatefulWidget` dialog: create in `initState`, dispose in `State.dispose`.

## Theme toggle on Profile

- Avoid `AnimatedContainer` on theme chips when tapping also swaps `MaterialApp.themeMode` — animation + full theme rebuild conflicts.
- Profile (and similar screens) must use `Theme.of(context)` / `colorScheme` for surfaces and text; hardcoded `AppPalette` light colors make Clair/Sombre look broken even when `themeMode` works.
- Shared chrome (`ReportNavigation`, etc.) must also use `colorScheme.surface` — a hardcoded `Colors.white` bottom bar stays white in dark mode.
- Same dispose bug hit Observations « Signaler » dialog (`observations_screen.dart`) — always use StatefulWidget-owned controllers for any dialog with TextField.
