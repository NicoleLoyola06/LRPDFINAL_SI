import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'reportes_service.dart';

class ChatMessage {
  final String rol; // 'user' o 'assistant'
  final String texto;
  const ChatMessage({required this.rol, required this.texto});
}

class ChatService {
  final String rutaProyecto;
  final ReportesService reportesService;

  // Modelo de Claude a usar. Puedes cambiar a "claude-haiku-4-5-20251001"
  // si quieres respuestas más baratas y rápidas (menos capaz para
  // preguntas complejas).
  static const String modelo = "claude-sonnet-5";

  ChatService(this.rutaProyecto) : reportesService = ReportesService(rutaProyecto);

  String get _rutaApiKey => p.join(rutaProyecto, 'config', 'anthropic_api_key.txt');

  Future<bool> tieneApiKey() async {
    final archivo = File(_rutaApiKey);
    if (!await archivo.exists()) return false;
    final contenido = (await archivo.readAsString()).trim();
    return contenido.isNotEmpty;
  }

  Future<void> guardarApiKey(String key) async {
    final archivo = File(_rutaApiKey);
    await archivo.parent.create(recursive: true);
    await archivo.writeAsString(key.trim());
  }

  Future<String> _leerApiKey() async {
    final archivo = File(_rutaApiKey);
    if (!await archivo.exists()) {
      throw Exception('No se ha configurado la API key de Anthropic.');
    }
    final key = (await archivo.readAsString()).trim();
    if (key.isEmpty) {
      throw Exception('La API key guardada está vacía.');
    }
    return key;
  }

  /// Arma un resumen en texto plano de los reportes actuales para
  /// dárselo a Claude como contexto. Se limita el número de filas
  /// por reporte para no gastar tokens de más.
  String _construirContexto() {
    final buffer = StringBuffer();

    void agregarReporte(String titulo, String archivo, {int maxFilas = 40}) {
      final reporte = reportesService.leerCsv(archivo);
      buffer.writeln('### $titulo');
      if (!reporte.existe) {
        buffer.writeln('(No disponible todavía, no se ha reentrenado el modelo)');
        buffer.writeln();
        return;
      }
      buffer.writeln(reporte.columnas.join(' | '));
      for (final fila in reporte.filas.take(maxFilas)) {
        buffer.writeln(fila.join(' | '));
      }
      if (reporte.filas.length > maxFilas) {
        buffer.writeln('... (${reporte.filas.length - maxFilas} filas más no mostradas)');
      }
      buffer.writeln();
    }

    agregarReporte('Recomendaciones por producto', 'recomendaciones.csv');
    agregarReporte('Tendencias de importación por categoría', 'tendencias_importacion.csv');
    agregarReporte('Productos a importar más', 'productos_a_importar.csv');
    agregarReporte('Productos a reducir/descontinuar', 'productos_a_reducir.csv');
    agregarReporte('Métricas de los modelos', 'metricas_modelos.csv', maxFilas: 10);

    return buffer.toString();
  }

  Future<String> preguntar(List<ChatMessage> historial, String pregunta) async {
    final apiKey = await _leerApiKey();
    final contexto = _construirContexto();

    final systemPrompt =
        'Eres el asistente del sistema de inventario del Supermercado Oriental. '
        'Respondes SOLO preguntas relacionadas con el inventario, las ventas, '
        'las recomendaciones y las métricas del modelo, usando ÚNICAMENTE los '
        'datos que se te dan a continuación. Si la pregunta no se puede '
        'responder con estos datos, dilo claramente en vez de inventar '
        'información. Responde en español, de forma breve y concreta.\n\n'
        '$contexto';

    final mensajes = [
      ...historial.map((m) => {'role': m.rol, 'content': m.texto}),
      {'role': 'user', 'content': pregunta},
    ];

    final respuesta = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': modelo,
        'max_tokens': 1024,
        'system': systemPrompt,
        'messages': mensajes,
      }),
    );

    if (respuesta.statusCode != 200) {
      throw Exception(
        'Error de la API (${respuesta.statusCode}): ${respuesta.body}',
      );
    }

    final data = jsonDecode(utf8.decode(respuesta.bodyBytes));
    final bloques = data['content'] as List<dynamic>;
    final texto = bloques
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String)
        .join('\n');

    return texto.isEmpty ? '(Sin respuesta de texto)' : texto;
  }
}