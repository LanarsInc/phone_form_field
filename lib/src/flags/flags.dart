import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Flag extends StatelessWidget {
  final BytesLoader loader;

  final double size;
  final bool isFlagCircle;

  Flag(
    String isoCode, {
    super.key,
    this.size = 48,
    this.isFlagCircle = true,
    FlagCache? cache,
  }) : loader = _createLoader(cache, isoCode);

  /// check if a flag has been preloaded if so, returns its byteloader
  static BytesLoader _createLoader(FlagCache? cache, String isoCode) {
    final cacheEntry = cache?._loaders[isoCode];
    if (cacheEntry != null) {
      return cacheEntry;
    }
    return _FlagAssetLoader(isoCode);
  }

  const Flag.fromLoader(this.loader, {super.key, this.size = 48, this.isFlagCircle = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      height: size,
      width: size,
      decoration: BoxDecoration(shape: isFlagCircle ? BoxShape.circle : BoxShape.rectangle),
      clipBehavior: Clip.hardEdge,
      child: SvgPicture(
        loader,
        width: size,
        height: size,
        fit: isFlagCircle ? BoxFit.fill : BoxFit.contain,
      ),
    );
  }
}

/// create an SvgAssetLoader that points to circle flag svg file
/// it will resolve to the "?" flag if the normal asset is not found
class _FlagAssetLoader extends SvgAssetLoader {
  final String isoCode;

  _FlagAssetLoader(this.isoCode) : super(computeAssetName(isoCode));

  static String computeAssetName(String isoCode) {
    return 'packages/phone_form_field/assets/svg/${isoCode.toLowerCase()}.svg';
  }

  static Future<ByteData> loadAsset(String assetName,
      [BuildContext? context, AssetBundle? assetBundle]) {
    final bundle = _FlagAssetLoader._resolveBundle(assetBundle, context);
    return bundle
        .load(assetName)
        // if any error loading a flag try to show the "?" flag
        .catchError((e) => rootBundle.load(_FlagAssetLoader.computeAssetName('xx')));
  }

  static AssetBundle _resolveBundle(AssetBundle? assetBundle, BuildContext? context) {
    if (assetBundle != null) {
      return assetBundle;
    }
    if (context != null) {
      return DefaultAssetBundle.of(context);
    }
    return rootBundle;
  }

  @override
  Future<ByteData?> prepareMessage(BuildContext? context) {
    final bundle = _resolveBundle(assetBundle, context);
    return bundle
        .load(computeAssetName(isoCode))
        // load "?" on error
        .catchError((e) => bundle.load(computeAssetName('xx')));
  }

  @override
  String provideSvg(ByteData? message) =>
      utf8.decode(message!.buffer.asUint8List(), allowMalformed: true);

  @override
  SvgCacheKey cacheKey(BuildContext? context) {
    return SvgCacheKey(keyData: isoCode, theme: theme, colorMapper: colorMapper);
  }
}

/// a flag loader cache that allows for preloading
/// svg bytes.
/// Currently only caches preloaded items
class FlagCache {
  final _loaders = <String, SvgBytesLoader>{};

  /// preloads flag data into svg cache
  preload(
    Iterable<String> isoCodes, [
    BuildContext? context,
    AssetBundle? assetBundle,
  ]) async {
    final tasks = <Future>[];
    for (final isoCode in isoCodes) {
      final task = _createLoader(isoCode, context, assetBundle)
          .then((loader) => _addLoaderToCache(isoCode, loader));
      tasks.add(task);
    }
    await Future.wait(tasks);
  }

  Future<SvgBytesLoader> _createLoader(
      String isoCode, BuildContext? context, AssetBundle? assetBundle) async {
    final assetName = _FlagAssetLoader.computeAssetName(isoCode);
    final byteData = await _FlagAssetLoader.loadAsset(assetName, context, assetBundle);
    final loader = SvgBytesLoader(Uint8List.sublistView(byteData));
    // add it to svg cache
    svg.cache.putIfAbsent(loader.cacheKey(context), () => loader.loadBytes(context));
    return loader;
  }

  void _addLoaderToCache(
    String isoCode,
    SvgBytesLoader loader,
  ) {
    _loaders[isoCode] = loader;
  }
}
