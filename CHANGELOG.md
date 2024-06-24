## [3.1.1]
- Deprecated dismissCompleter in modal flash.

## [3.1.0] - 2023-11-22
- Migrate to flutter 3.16.0 .

## [3.0.5+2] - 2023-10-27
- Add `onRemoveFromRoute` in `DefaultFlashController`, it only works when `persistent` is false.

## [3.0.5+1] - 2023-5-30
- `FlashBar` add `builder` param to warp child.

## [3.0.5] - 2023-5-19
- Fix remove view insets of child.

## [3.0.4] - 2023-5-18
- Fix using safe area is now optional.

## [3.0.3+5] - 2023-4-27
- Change the default Toast text style to bodyLarge.

## [3.0.3+4] - 2023-4-26
- Fix: set FLash hit test behavior to `HitTestBehavior.deferToChild`.
- Add context for slide animation creator.
- Fix: create slide animation before initState completed.

## [3.0.3] - 2023-4-25
- Refactor: flash dismiss direction and add slideAnimationCreator to customize slide animation.

## [3.0.2] - 2023-4-24
- Fix: wrap captured theme child with Builder.
- Feat: add onBarrierTap. optimize default flash theme.
- Fix: Flash animation handle.

## [3.0.1] - 2023-4-3
- Add default FlashBarTheme and FlashToastTheme.

## [3.0.0] - 2023-4-3
- Publish 3.0.0

## [3.0.0-dev+1] - 2023-2-17
- Refactor.
- Add flash route.
- Use ThemeExtension.

## [3.0.0-dev] - 2023-2-15

## [2.0.6] - 2023-2-13
- Will pop add the controller param.

## [2.0.5+1] - 2023-2-13
- Remove some about focusScopeNode.

## [2.0.5] - 2022-9-27
- Add `copyWith` method for theme data.

## [2.0.4] - 2022-9-27
- Add `position` optional param for `FlashBarShortcuts`.

## [2.0.3+3] - 2022-7-19
- Fix #49

## [2.0.3+2] - 2022-1-7
- Add `constraints` optional params for `Flash`.
- Add `transitionDuration` and `constraints` configuration.

## [2.0.3+1] - 2021-12-13
- Add return `Future` for `Flash.dismiss`.

## [2.0.3] - 2021-9-30
- Add return `Future` for `Flash.dismiss`.

## [2.0.2] - 2021-9-22
- Add optional params for `Toast`.

## [2.0.1] - 2021-6-23
- Add optional params useSafeArea.

## [2.0.0] - 2021-5-17
- Restructure.
- Add context shortcuts.
- Add theme configuration.

## [1.5.2+2] - 2021-5-13
- fix: #22 #23.

## [1.5.2+1] - 2021-4-28
- Remove optional params rootNavigator.
- Change the method of finding root overlay.

## [1.5.2] - 2021-4-28
- Add optional params rootNavigator.

## [1.5.1] - 2021-3-25
- Fix return value to nullable.

## [1.5.0] - 2021-3-9
- Stable null-safety release

## [1.4.0-nullsafety] - 2020-11-19

- Migrate to null safety.
- Update example.

## [1.3.1] - 2020-4-25

- Add `FlashController.isDisposed` .

## [1.3.0] - 2020-4-21

- Remove `userInputForm`.

## [1.2.4] - 2020-4-10

- Hide soft keyboard like a route when show a not persistent flash.
- In the example, because WillPopScope conflicts with FlashController.onWillPop, use [BackButtonInterceptor](https://pub.dev/packages/back_button_interceptor) instead of WillPopScope.

## [1.2.3] - 2020-3-18

- Fix `FlashBuilder` type not match.

## [1.2.2] - 2020-3-17

- Adjust message bottom margin.

## [1.2.1] - 2020-3-17

- Remove deprecated method.
- Remove unused variable. 

## [1.2.0] - 2019-10-14

### Added
- Dismiss with horizontal drag.
- Added `FlashHelper` for example. 

## [1.1.0+2] - 2019-8-14

### Fixes
- `margin` added null checks 

## [1.1.0+1] - 2019-8-14

### Fixes
- Fixed animation dismissed but `dismissInternal()` not called.

## [1.1.0] - 2019-8-13

### Changed
- Rename to flash
- Refactoring code makes it easier to customize content

### Added
- `FlashPosition.center`

## [1.0.0] - 2019-8-7

### Added
- Flashbar creation
