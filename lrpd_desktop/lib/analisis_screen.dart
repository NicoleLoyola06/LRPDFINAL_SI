import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/reportes_service.dart';
import 'services/python_service.dart';
import 'theme/app_colors.dart';

class _DefReporte {
  final String clave;
  final String titulo;
  final String archivo;
  final IconData icono;
  const _DefReporte(this.clave, this.titulo, this.archivo, this.icono);
}

const String _claveGraficos = 'graficos';

const List<_DefReporte> _reportesDisponibles = [
  _DefReporte('recomendaciones', 'Recomendaciones', 'recomendaciones.csv', Icons.lightbulb_outline),
  _DefReporte('priorizados', 'Priorizados', 'productos_priorizados.csv', Icons.star_outline),
  _DefReporte('importar', 'A importar', 'productos_a_importar.csv', Icons.call_received_rounded),
  _DefReporte('reducir', 'A reducir', 'productos_a_reducir.csv', Icons.call_made_rounded),
  _DefReporte('tendencias', 'Tendencias', 'tendencias_importacion.csv', Icons.trending_up_rounded),
  _DefReporte('metricas', 'Métricas del modelo', 'metricas_modelos.csv', Icons.analytics_outlined),
];

const Map<String, String> _tituloGrafico = {
  'arbol_decision.png': 'Árbol de decisión',
  'demanda_real_vs_predicha.png': 'Demanda real vs. predicha',
  'matriz_confusion.png': 'Matriz de confusión',
};

class AnalisisScreen extends StatefulWidget {
  final ReportesService reportesService;
  const AnalisisScreen({super.key, required this.reportesService});

  @override
  State<AnalisisScreen> createState() => _AnalisisScreenState();
}

class _AnalisisScreenState extends State<AnalisisScreen> {
  String _claveSeleccionada = _reportesDisponibles.first.clave;
  final Map<String, ReporteCSV> _cache = {};
  String _busquedaTabla = '';

  ReporteCSV _obtenerReporte(String clave) {
    final def = _reportesDisponibles.firstWhere((d) => d.clave == clave);
    return _cache.putIfAbsent(clave, () => widget.reportesService.leerCsv(def.archivo));
  }

  void _refrescar() {
    setState(() => _cache.clear());
  }

  Future<void> _abrirReentrenamiento() async {
    final exitoso = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogoReentrenamiento(
        pythonService: PythonService(widget.reportesService.rutaProyecto),
      ),
    );
    if (exitoso == true) {
      _refrescar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final esGraficos = _claveSeleccionada == _claveGraficos;
    final reporteActual = esGraficos ? null : _obtenerReporte(_claveSeleccionada);

    return Scaffold(
      backgroundColor: AppColors.fondoOscuro,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => AppColors.gradienteAccent.createShader(bounds),
                          child: const Text(
                            'Análisis Inteligente',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          esGraficos
                              ? 'Gráficos generados por modelos.py'
                              : reporteActual != null && reporteActual.existe && reporteActual.actualizado != null
                              ? 'Última actualización: ${DateFormat('dd/MM/yyyy HH:mm').format(reporteActual.actualizado!)}'
                              : 'Aún no se ha generado este reporte',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textoSec, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: _abrirReentrenamiento,
                        icon: const Icon(Icons.model_training_rounded, size: 18, color: AppColors.amarillo),
                        label: const Text(
                          'Reentrenar',
                          style: TextStyle(color: AppColors.amarillo, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _reportesDisponibles.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  if (i == _reportesDisponibles.length) {
                    return _ChipReporte(
                      icono: Icons.image_outlined,
                      texto: 'Gráficos',
                      seleccionada: esGraficos,
                      onTap: () => setState(() => _claveSeleccionada = _claveGraficos),
                    );
                  }
                  final def = _reportesDisponibles[i];
                  return _ChipReporte(
                    icono: def.icono,
                    texto: def.titulo,
                    seleccionada: _claveSeleccionada == def.clave,
                    onTap: () => setState(() => _claveSeleccionada = def.clave),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: esGraficos
                  ? _GaleriaGraficos(reportesService: widget.reportesService)
                  : _TablaReporte(
                reporte: reporteActual!,
                nombreArchivo: _reportesDisponibles.firstWhere((d) => d.clave == _claveSeleccionada).archivo,
                busqueda: _busquedaTabla,
                onBusquedaCambia: (v) => setState(() => _busquedaTabla = v),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipReporte extends StatelessWidget {
  final IconData icono;
  final String texto;
  final bool seleccionada;
  final VoidCallback onTap;

  const _ChipReporte({
    required this.icono,
    required this.texto,
    required this.seleccionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppColors.dFast,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: seleccionada ? AppColors.amberBg : AppColors.fondoField,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: seleccionada ? AppColors.naranja : AppColors.borde),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 14, color: seleccionada ? AppColors.amarillo : AppColors.textoSec),
            const SizedBox(width: 6),
            Text(
              texto,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: seleccionada ? AppColors.amarillo : AppColors.textoSec,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TablaReporte extends StatelessWidget {
  final ReporteCSV reporte;
  final String nombreArchivo;
  final String busqueda;
  final ValueChanged<String> onBusquedaCambia;

  const _TablaReporte({
    required this.reporte,
    required this.nombreArchivo,
    required this.busqueda,
    required this.onBusquedaCambia,
  });

  static const int _limiteFilas = 300;

  @override
  Widget build(BuildContext context) {
    if (!reporte.existe) {
      return _EstadoVacioReporte(nombreArchivo: nombreArchivo);
    }

    final filasFiltradas = busqueda.isEmpty
        ? reporte.filas
        : reporte.filas
        .where((fila) => fila.any((v) => v.toLowerCase().contains(busqueda.toLowerCase())))
        .toList();

    final filasMostradas = filasFiltradas.length > _limiteFilas
        ? filasFiltradas.sublist(0, _limiteFilas)
        : filasFiltradas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            style: const TextStyle(color: AppColors.textoPri),
            decoration: InputDecoration(
              hintText: 'Buscar en $nombreArchivo...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textoSec, size: 20),
            ),
            onChanged: onBusquedaCambia,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            filasFiltradas.length > _limiteFilas
                ? 'Mostrando $_limiteFilas de ${filasFiltradas.length} filas'
                : '${filasFiltradas.length} filas',
            style: const TextStyle(fontSize: 11.5, color: AppColors.textoMuted, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filasMostradas.isEmpty
              ? const Center(
            child: Text('Sin resultados para esta búsqueda', style: TextStyle(color: AppColors.textoSec)),
          )
              : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borde),
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppColors.fondoCard),
                      dataRowColor: WidgetStateProperty.all(AppColors.fondoOscuro),
                      columns: reporte.columnas
                          .map((c) => DataColumn(
                        label: Text(
                          c,
                          style: const TextStyle(
                            color: AppColors.amarillo,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ))
                          .toList(),
                      rows: filasMostradas
                          .map(
                            (fila) => DataRow(
                          cells: List.generate(
                            reporte.columnas.length,
                                (i) => DataCell(
                              Text(
                                i < fila.length ? fila[i] : '',
                                style: const TextStyle(color: AppColors.textoPri, fontSize: 12.5),
                              ),
                            ),
                          ),
                        ),
                      )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _GaleriaGraficos extends StatelessWidget {
  final ReportesService reportesService;
  const _GaleriaGraficos({required this.reportesService});

  @override
  Widget build(BuildContext context) {
    final graficos = reportesService.listarGraficos();

    if (graficos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_not_supported_outlined, size: 48, color: AppColors.textoMuted),
            const SizedBox(height: 12),
            const Text('No se encontraron gráficos', style: TextStyle(color: AppColors.textoSec, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Se esperan en:\n${reportesService.rutaGraficos}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textoMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.95,
      ),
      itemCount: graficos.length,
      itemBuilder: (_, i) {
        final archivo = graficos[i];
        final nombreBase = archivo.path.split(Platform.pathSeparator).last;
        final titulo = _tituloGrafico[nombreBase] ?? nombreBase;

        return GestureDetector(
          onTap: () => _abrirVisor(context, archivo, titulo),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.fondoCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borde),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: Image.file(
                    archivo,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) =>
                    const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.textoMuted)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textoPri, fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _abrirVisor(BuildContext context, File archivo, String titulo) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.fondoOscuro,
        insetPadding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(titulo,
                        style: const TextStyle(color: AppColors.textoPri, fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textoSec),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: Image.file(archivo),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoVacioReporte extends StatelessWidget {
  final String nombreArchivo;
  const _EstadoVacioReporte({required this.nombreArchivo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.table_chart_outlined, size: 48, color: AppColors.textoMuted),
          const SizedBox(height: 12),
          Text(
            'Aún no existe $nombreArchivo',
            style: const TextStyle(color: AppColors.textoSec, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ejecuta el PASO 4 (preprocesamiento.py → modelos.py → busqueda.py/agente.py)\ny presiona Actualizar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textoMuted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

enum _EstadoProceso { verificando, ejecutando, exitoso, error, cancelado }

class _DialogoReentrenamiento extends StatefulWidget {
  final PythonService pythonService;
  const _DialogoReentrenamiento({required this.pythonService});

  @override
  State<_DialogoReentrenamiento> createState() => _DialogoReentrenamientoState();
}

class _DialogoReentrenamientoState extends State<_DialogoReentrenamiento> {
  final List<String> _lineas = [];
  final ScrollController _scroll = ScrollController();
  _EstadoProceso _estado = _EstadoProceso.verificando;
  int? _codigoSalida;
  bool _verDetalles = false;
  bool _tardandoMucho = false;
  void Function()? _cancelarProceso;
  Timer? _timerAviso;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  @override
  void dispose() {
    _timerAviso?.cancel();
    _cancelarProceso?.call();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _iniciar() async {
    final pythonOk = await widget.pythonService.verificarPython();
    if (!mounted) return;

    if (!pythonOk) {
      setState(() {
        _estado = _EstadoProceso.error;
        _verDetalles = true;
        _lineas.add(
          'No se pudo verificar el intérprete de Python configurado.\n'
              'Revisa que "comandoPython" en PythonService apunte a la ruta '
              'correcta de tu python.exe.',
        );
      });
      return;
    }

    setState(() => _estado = _EstadoProceso.ejecutando);

    _timerAviso = Timer(const Duration(seconds: 20), () {
      if (mounted && _estado == _EstadoProceso.ejecutando) {
        setState(() {
          _tardandoMucho = true;
          _verDetalles = true;
        });
      }
    });

    final ejecucion = await widget.pythonService.ejecutarMain();
    _cancelarProceso = ejecucion.cancelar;

    ejecucion.lineas.listen((linea) {
      if (!mounted) return;
      setState(() => _lineas.add(linea));
      _scrollAlFinal();
    });

    final codigo = await ejecucion.codigoSalida;
    _timerAviso?.cancel();
    if (!mounted) return;
    setState(() {
      _codigoSalida = codigo;
      _estado = codigo == 0 ? _EstadoProceso.exitoso : _EstadoProceso.error;
      if (_estado == _EstadoProceso.error) _verDetalles = true;
    });
  }

  void _cancelar() {
    _cancelarProceso?.call();
    setState(() => _estado = _EstadoProceso.cancelado);
  }

  @override
  Widget build(BuildContext context) {
    final enProgreso = _estado == _EstadoProceso.verificando || _estado == _EstadoProceso.ejecutando;

    return PopScope(
      canPop: !enProgreso,
      child: Dialog(
        backgroundColor: AppColors.fondoCard,
        insetPadding: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (enProgreso)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.amarillo),
                    )
                  else
                    Icon(
                      _estado == _EstadoProceso.exitoso
                          ? Icons.check_circle
                          : _estado == _EstadoProceso.cancelado
                          ? Icons.info
                          : Icons.error,
                      color: _estado == _EstadoProceso.exitoso ? AppColors.exito : AppColors.error,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _estado == _EstadoProceso.verificando
                          ? 'Verificando entorno de Python...'
                          : _estado == _EstadoProceso.ejecutando
                          ? 'Reentrenando modelo...'
                          : _estado == _EstadoProceso.exitoso
                          ? 'Listo, resultados actualizados'
                          : _estado == _EstadoProceso.cancelado
                          ? 'Reentrenamiento cancelado'
                          : 'Ocurrió un error',
                      style: const TextStyle(color: AppColors.textoPri, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _estado == _EstadoProceso.ejecutando
                    ? (_tardandoMucho
                    ? 'Esto está tardando más de lo normal. Revisa la consola abajo para ver en qué paso va.'
                    : 'Esto puede tardar unos segundos...')
                    : _estado == _EstadoProceso.exitoso
                    ? 'Las tablas y gráficos ya reflejan el nuevo análisis.'
                    : '',
                style: const TextStyle(color: AppColors.textoSec, fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              if (_estado != _EstadoProceso.verificando)
                TextButton(
                  onPressed: () => setState(() => _verDetalles = !_verDetalles),
                  child: Text(
                    _verDetalles ? 'Ocultar consola' : 'Ver detalles técnicos',
                    style: const TextStyle(color: AppColors.amarillo, fontSize: 12),
                  ),
                ),
              if (_verDetalles)
                Container(
                  width: 520,
                  height: 260,
                  margin: const EdgeInsets.only(top: 4, bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.fondoOscuro,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borde),
                  ),
                  child: _lineas.isEmpty
                      ? const Center(
                    child: Text(
                      'Aún no hay salida de consola...',
                      style: TextStyle(color: AppColors.textoMuted, fontSize: 12),
                    ),
                  )
                      : Scrollbar(
                    controller: _scroll,
                    child: ListView.builder(
                      controller: _scroll,
                      itemCount: _lineas.length,
                      itemBuilder: (_, i) => Text(
                        _lineas[i],
                        style: const TextStyle(
                          color: AppColors.textoSec,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (enProgreso)
                      TextButton(
                        onPressed: _cancelar,
                        child: const Text('Cancelar', style: TextStyle(color: AppColors.textoSec)),
                      ),
                    if (!enProgreso)
                      TextButton(
                        onPressed: () => Navigator.pop(context, _estado == _EstadoProceso.exitoso),
                        child: const Text(
                          'Cerrar',
                          style: TextStyle(color: AppColors.amarillo, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}