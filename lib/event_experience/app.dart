import 'package:flutter/material.dart';

import 'config/app_brand.dart';
import 'data/event_api_client.dart';
import 'screens/home_screen.dart';

typedef BrandLoader = Future<AppBrand> Function(String eventCode);

class CongressApp extends StatefulWidget {
  const CongressApp({required this.brand, this.brandLoader, super.key});

  final AppBrand brand;
  final BrandLoader? brandLoader;

  @override
  State<CongressApp> createState() => _CongressAppState();
}

class _CongressAppState extends State<CongressApp> {
  late Future<AppBrand> brandFuture;

  @override
  void initState() {
    super.initState();
    _loadBrand();
  }

  void _loadBrand() {
    brandFuture = (widget.brandLoader ?? EventApiClient().fetchBrand)(
      widget.brand.code,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppBrand>(
      future: brandFuture,
      builder: (context, snapshot) {
        final brand = snapshot.data ?? widget.brand;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: brand.name,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: brand.primaryColor),
            scaffoldBackgroundColor: const Color(0xFFF7F7F5),
            useMaterial3: true,
            splashFactory: InkSparkle.splashFactory,
            navigationBarTheme: NavigationBarThemeData(
              labelTextStyle: WidgetStateProperty.resolveWith(
                (states) => TextStyle(
                  color: states.contains(WidgetState.selected)
                      ? brand.primaryColor
                      : const Color(0xFF667085),
                  fontSize: 11,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w800
                      : FontWeight.w600,
                ),
              ),
            ),
            cardTheme: const CardThemeData(
              elevation: 0,
              margin: EdgeInsets.zero,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
          ),
          home: snapshot.connectionState == ConnectionState.waiting
              ? _LoadingScreen(brand: brand)
              : snapshot.hasError
              ? _ApiErrorScreen(
                  brand: brand,
                  error: snapshot.error!,
                  onRetry: () => setState(_loadBrand),
                )
              : HomeScreen(brand: brand),
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({required this.brand});
  final AppBrand brand;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 132,
            height: 76,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: brand.primaryColor.withValues(alpha: .12),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Image.asset(
              brand.logoAsset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          const Text('Loading congress information…'),
        ],
      ),
    ),
  );
}

class _ApiErrorScreen extends StatelessWidget {
  const _ApiErrorScreen({
    required this.brand,
    required this.error,
    required this.onRetry,
  });
  final AppBrand brand;
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: brand.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Could not connect to the event server',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    ),
  );
}
