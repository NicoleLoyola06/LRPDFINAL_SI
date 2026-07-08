import 'dart:io';
import 'package:path/path.dart' as p;

class ReporteCSV {
  final List<String> columnas;
  final List<List<String>> filas;
  final DateTime? actualizado;
  final bool existe;

  const ReporteCSV({
    required this.columnas,
    required this.filas,
    required this.actualizado,
    required this.existe,
  });

  static const vacio = ReporteCSV(
    columnas: [],
    filas: [],
    actualizado: null,
    existe: false,
  );
}

class ReportesService {
  final String rutaProyecto;
  late final String rutaReportes;
  late final String rutaGraficos;

  ReportesService(this.rutaProyecto) {
    final candidatoRaiz = p.join(rutaProyecto, 'reportes');
    final candidatoOutputs = p.join(rutaProyecto, 'outputs', 'reportes');
    rutaReportes = Directory(candidatoRaiz).existsSync() ? candidatoRaiz : candidatoOutputs;
    rutaGraficos = p.join(rutaProyecto, 'outputs', 'Graficos');
  }

  ReporteCSV leerCsv(String nombreArchivo) {
    final archivo = File(p.join(rutaReportes, nombreArchivo));
    if (!archivo.existsSync()) return ReporteCSV.vacio;

    final contenido = archivo.readAsStringSync();
    final lineas = _parsearCsv(contenido);
    if (lineas.isEmpty) return ReporteCSV.vacio;

    final columnas = lineas.first;
    final filas = lineas.length > 1 ? lineas.sublist(1) : <List<String>>[];

    return ReporteCSV(
      columnas: columnas,
      filas: filas,
      actualizado: archivo.lastModifiedSync(),
      existe: true,
    );
  }

  List<File> listarGraficos() {
    final dir = Directory(rutaGraficos);
    if (!dir.existsSync()) return [];
    final extensionesValidas = {'.png', '.jpg', '.jpeg'};
    final archivos = dir
        .listSync()
        .whereType<File>()
        .where((f) => extensionesValidas.contains(p.extension(f.path).toLowerCase()))
        .toList();
    archivos.sort((a, b) => a.path.compareTo(b.path));
    return archivos;
  }

  List<List<String>> _parsearCsv(String contenido) {
    final filas = <List<String>>[];
    var fila = <String>[];
    var campo = StringBuffer();
    var dentroDeComillas = false;

    final texto = contenido.replaceAll('\r\n', '\n');
    for (var i = 0; i < texto.length; i++) {
      final c = texto[i];

      if (dentroDeComillas) {
        if (c == '"') {
          if (i + 1 < texto.length && texto[i + 1] == '"') {
            campo.write('"');
            i++;
          } else {
            dentroDeComillas = false;
          }
        } else {
          campo.write(c);
        }
      } else {
        if (c == '"') {
          dentroDeComillas = true;
        } else if (c == ',') {
          fila.add(campo.toString());
          campo = StringBuffer();
        } else if (c == '\n') {
          fila.add(campo.toString());
          campo = StringBuffer();
          if (fila.any((v) => v.trim().isNotEmpty)) filas.add(fila);
          fila = <String>[];
        } else {
          campo.write(c);
        }
      }
    }
    if (campo.isNotEmpty || fila.isNotEmpty) {
      fila.add(campo.toString());
      if (fila.any((v) => v.trim().isNotEmpty)) filas.add(fila);
    }
    return filas;
  }
}