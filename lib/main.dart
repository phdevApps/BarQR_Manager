import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barqr_manager/navigation_cubit.dart';
import 'app_theme.dart';
import 'scanned_results_cubit.dart';
import 'my_home_page.dart';
import 'theme_cubit.dart';  // Now imported from separate file

void main() {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ScannedResultsCubit()),
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => NavigationCubit()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeData>(
      builder: (context, theme) {
        return MaterialApp(
          title: 'BarQR Manager',
          theme: theme,
          debugShowCheckedModeBanner: false,
          home:  MyHomePage(),
          // Remove darkTheme property as it's now handled by ThemeCubit
        );
      },
    );
  }
}
