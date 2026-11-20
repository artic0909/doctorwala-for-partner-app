import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'core/app_colors.dart';

void main() {
  runApp(const DoctorWalaPartnerApp());
}

class DoctorWalaPartnerApp extends StatelessWidget {
  const DoctorWalaPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DoctorWala Partner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      builder: (context, child) {
        // Enforce safe responsive text scaling so system accessibility settings
        // do not break mobile UI layouts across varying phone screen sizes
        final mediaQueryData = MediaQuery.of(context);
        final clampedScale = mediaQueryData.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.15,
        );
        return MediaQuery(
          data: mediaQueryData.copyWith(textScaler: clampedScale),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}
 