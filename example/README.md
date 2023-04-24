# example

A new Flutter project.

## Run Web

```bash
flutter run --release --dart-define=FLUTTER_WEB_USE_SKIA=true -d chrome
```

## Build Web

```bash
flutter build web --dart-define=FLUTTER_WEB_USE_SKIA=true --release
```

- Build Flutter web app to Github Pages to the docs folder

```bash
flutter build web --web-renderer html --base-href /flash/ --release && rm -rf ../docs && mkdir ../docs && cp -a ./build/web/. ../docs/
```