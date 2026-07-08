import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'db_service.dart';
import 'login_screen.dart';
import 'inventario_screen.dart';
import 'ventas_screen.dart';
import 'analisis_screen.dart';
import 'services/reportes_service.dart';
import '/services/chat_screen.dart';

const String rutaDb = r"D:\LRPD_sI\LRPD_sI\data\inventario.db";
const String rutaProyecto = r"D:\LRPD_sI\LRPD_sI";// misma ruta que usa Python

void main() => runApp(const LrpdApp());

class LrpdApp extends StatelessWidget {
  const LrpdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LRPD - Gestión de Inventario',
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: RaizApp(dbService: DBService(rutaDb)),
    );
  }
}

class RaizApp extends StatefulWidget {
  final DBService dbService;
  const RaizApp({super.key, required this.dbService});

  @override
  State<RaizApp> createState() => _RaizAppState();
}

class _RaizAppState extends State<RaizApp> {
  bool _autenticado = false;

  @override
  Widget build(BuildContext context) {
    if (!_autenticado) {
      return LoginScreen(
        dbService: widget.dbService,
        onLoginExitoso: () => setState(() => _autenticado = true),
      );
    }
    return HomeShell(dbService: widget.dbService);
  }
}

class HomeShell extends StatefulWidget {
  final DBService dbService;
  const HomeShell({super.key, required this.dbService});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tabActual = 0;
  late final ReportesService _reportesService = ReportesService(rutaProyecto);

  @override
  Widget build(BuildContext context) {
    final pantallas = [
      InventarioScreen(dbService: widget.dbService),
      VentasScreen(dbService: widget.dbService),
      AnalisisScreen(reportesService: _reportesService),
      const ChatScreen(rutaProyecto: rutaProyecto),
    ];

    return Scaffold(
      backgroundColor: AppColors.fondoOscuro,
      body: pantallas[_tabActual],
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.fondoCard,
        selectedIndex: _tabActual,
        onDestinationSelected: (i) => setState(() => _tabActual = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Inventario'),
          NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), label: 'Ventas'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Análisis'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Chatbot'),
        ],
      ),
    );
  }
}