import 'package:flutter/material.dart';
import 'package:attendance_tracking/screens/login_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'providers/settings_provider.dart'; // Import SettingsProvider

import 'package:flutter/services.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Consume the SettingsProvider
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        final primaryColor =
            settings.primaryColor; // Get the current primary color

        // Define base ThemeData (Light Theme)
        final baseTheme = ThemeData(
          brightness: Brightness.light,
          textTheme: GoogleFonts.outfitTextTheme(
            ThemeData(
              brightness: Brightness.light,
            ).textTheme, // Use light theme base
          ),
          primarySwatch: primaryColor,
          colorScheme:
              ColorScheme.fromSwatch(
                primarySwatch: primaryColor,
                brightness: Brightness.light,
              ).copyWith(
                primary: primaryColor,
                secondary:
                    primaryColor[400], // Adjust secondary shade if needed
                surface: Colors.white,
                background: Colors.grey[100], // Slightly lighter grey
              ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          scaffoldBackgroundColor: Colors.white, // Slightly lighter grey
          cardColor: Colors.white,
          dialogBackgroundColor: Colors.white,
          dividerColor: Colors.grey[200],
          appBarTheme: AppBarTheme(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 1.0,
            titleTextStyle: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            iconTheme: IconThemeData(color: Colors.white.withOpacity(0.9)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),
            labelStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.grey.shade100.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14.0,
              horizontal: 12.0,
            ),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: primaryColor,
            unselectedItemColor: Colors.grey.shade600,
            selectedLabelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w500,
              fontSize: 11.5,
            ),
            type: BottomNavigationBarType.fixed,
            elevation: 8.0,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
          // Add other theme properties as needed
        );

        // Define Dark ThemeData with darker colors
        final darkTheme = ThemeData(
          brightness: Brightness.dark,
          textTheme: GoogleFonts.outfitTextTheme(
            ThemeData(
              brightness: Brightness.dark,
            ).textTheme, // Use dark theme base
          ),
          primarySwatch: primaryColor,
          colorScheme:
              ColorScheme.fromSwatch(
                primarySwatch: primaryColor,
                brightness: Brightness.dark,
              ).copyWith(
                primary: primaryColor[300], // Lighter primary for dark mode
                secondary: primaryColor[600], // Darker secondary/accent
                surface: const Color(
                  0xFF1E1E1E,
                ), // Darker surface (cards, dialogs)
                background: const Color(0xFF121212), // Very dark background
                onPrimary: Colors.black87, // Text/icons on primary color
                onSecondary: Colors.white, // Text/icons on secondary color
                onSurface: Colors.white.withOpacity(
                  0.87,
                ), // Text/icons on surface
                onBackground: Colors.white.withOpacity(
                  0.87,
                ), // Text/icons on background
                onError: Colors.black87, // Text/icons on error color
              ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          scaffoldBackgroundColor: const Color(
            0xFF121212,
          ), // Very dark scaffold background
          cardColor: const Color(0xFF1E1E1E), // Darker card background
          dialogBackgroundColor: const Color(
            0xFF1E1E1E,
          ), // Darker dialog background
          dividerColor: Colors.white.withOpacity(0.12), // Subtle divider
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(
              0xFF1E1E1E,
            ), // Darker AppBar to match cards
            foregroundColor: Colors.white.withOpacity(
              0.87,
            ), // Lighter text/icons
            elevation: 1.0,
            titleTextStyle: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.87),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            iconTheme: IconThemeData(color: Colors.white.withOpacity(0.87)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor[300], // Lighter button background
              foregroundColor: Colors.black87, // Darker button text/icon
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor[300], // Lighter button text/icon
              side: BorderSide(color: primaryColor[300]!.withOpacity(0.7)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.23),
              ), // Lighter border
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.23),
              ), // Lighter border
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryColor[300]!, width: 1.5),
            ),
            labelStyle: TextStyle(
              color: Colors.white.withOpacity(0.6),
            ), // Lighter label
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.6),
            ), // Lighter hint
            fillColor: Colors.white.withOpacity(0.06), // Very subtle fill
            filled: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14.0,
              horizontal: 12.0,
            ),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: const Color(
              0xFF1E1E1E,
            ), // Match card/appbar background
            selectedItemColor: primaryColor[300],
            unselectedItemColor: Colors.white.withOpacity(
              0.6,
            ), // Lighter unselected
            selectedLabelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w500,
              fontSize: 11.5,
            ),
            type: BottomNavigationBarType.fixed,
            elevation: 8.0,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: primaryColor[300],
            foregroundColor: Colors.black87,
          ),
          // Add other dark theme properties
        );

        return MaterialApp(
          title: 'Workers App',
          theme: baseTheme,
          darkTheme: darkTheme,
          themeMode: settings.themeMode,
          home: const LoginPage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
