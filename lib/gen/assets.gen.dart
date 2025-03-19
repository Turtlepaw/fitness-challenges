/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: directives_ordering,unnecessary_import,implicit_dynamic_list_literal,deprecated_member_use

import 'package:flutter/widgets.dart';

class $ImagesGen {
  const $ImagesGen();

  /// File path: images/Bingo_WIP.png
  AssetGenImage get bingoWIP => const AssetGenImage('images/Bingo_WIP.png');

  /// File path: images/Bingo_WIP_2.png
  AssetGenImage get bingoWIP2 => const AssetGenImage('images/Bingo_WIP_2.png');

  /// File path: images/CommunityWIP.png
  AssetGenImage get communityWIP =>
      const AssetGenImage('images/CommunityWIP.png');

  /// File path: images/Onboarding.png
  AssetGenImage get onboarding => const AssetGenImage('images/Onboarding.png');

  /// File path: images/Screenshot_20240902_003413.png
  AssetGenImage get screenshot20240902003413 =>
      const AssetGenImage('images/Screenshot_20240902_003413.png');

  /// File path: images/Screenshot_20240902_003428.png
  AssetGenImage get screenshot20240902003428 =>
      const AssetGenImage('images/Screenshot_20240902_003428.png');

  /// File path: images/Screenshot_20240902_003443.png
  AssetGenImage get screenshot20240902003443 =>
      const AssetGenImage('images/Screenshot_20240902_003443.png');

  /// File path: images/Screenshot_20240902_003507.png
  AssetGenImage get screenshot20240902003507 =>
      const AssetGenImage('images/Screenshot_20240902_003507.png');

  /// File path: images/Wear_Screenshot (with shell).png
  AssetGenImage get wearScreenshotWithShell =>
      const AssetGenImage('images/Wear_Screenshot (with shell).png');

  /// File path: images/Wear_Screenshot_20240913_000143.png
  AssetGenImage get wearScreenshot20240913000143 =>
      const AssetGenImage('images/Wear_Screenshot_20240913_000143.png');

  /// File path: images/adaptive_icon.png
  AssetGenImage get adaptiveIcon =>
      const AssetGenImage('images/adaptive_icon.png');

  /// File path: images/background.png
  AssetGenImage get background => const AssetGenImage('images/background.png');

  /// File path: images/github-mark.png
  AssetGenImage get githubMark => const AssetGenImage('images/github-mark.png');

  /// File path: images/health_connect.png
  AssetGenImage get healthConnect =>
      const AssetGenImage('images/health_connect.png');

  /// File path: images/icon.png
  AssetGenImage get icon => const AssetGenImage('images/icon.png');

  /// File path: images/icon_rounded.png
  AssetGenImage get iconRounded =>
      const AssetGenImage('images/icon_rounded.png');

  /// File path: images/monochrome.png
  AssetGenImage get monochrome => const AssetGenImage('images/monochrome.png');

  /// File path: images/new_ui.webm
  String get newUi => 'images/new_ui.webm';

  /// File path: images/noto_awesome.svg
  String get notoAwesome => 'images/noto_awesome.svg';

  /// File path: images/play_feature_image.png
  AssetGenImage get playFeatureImage =>
      const AssetGenImage('images/play_feature_image.png');

  /// File path: images/rocket_launch.png
  AssetGenImage get rocketLaunch =>
      const AssetGenImage('images/rocket_launch.png');

  /// File path: images/wear_os.png
  AssetGenImage get wearOs => const AssetGenImage('images/wear_os.png');

  /// List of all assets
  List<dynamic> get values => [
        bingoWIP,
        bingoWIP2,
        communityWIP,
        onboarding,
        screenshot20240902003413,
        screenshot20240902003428,
        screenshot20240902003443,
        screenshot20240902003507,
        wearScreenshotWithShell,
        wearScreenshot20240913000143,
        adaptiveIcon,
        background,
        githubMark,
        healthConnect,
        icon,
        iconRounded,
        monochrome,
        newUi,
        notoAwesome,
        playFeatureImage,
        rocketLaunch,
        wearOs
      ];
}

class Assets {
  Assets._();

  static const $ImagesGen images = $ImagesGen();
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.low,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({
    AssetBundle? bundle,
    String? package,
  }) {
    return AssetImage(
      _assetName,
      bundle: bundle,
      package: package,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}
