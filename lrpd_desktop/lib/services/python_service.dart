import 'dart:async';
import 'dart:convert';
import 'dart:io';

class EjecucionPython {
  final Stream<String> lineas;
  final Future<int> codigoSalida;
  final void Function() cancelar;
  const EjecucionPython({
    required this.lineas,
    required this.codigoSalida,
    required this.cancelar,
  });
}

class PythonService {
  final String rutaProyecto;

  final String comandoPython;

  const PythonService(
      this.rutaProyecto, {
        this.comandoPython = r"C:\Users\LENOVO\AppData\Local\Programs\Python\Python313\python.exe",
      });

  Future<bool> verificarPython() async {
    try {
      final resultado = await Process.run(
        comandoPython,
        ['--version'],
        runInShell: true,
      ).timeout(const Duration(seconds: 6));
      return resultado.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<EjecucionPython> ejecutarMain() async {
    final controller = StreamController<String>();
    Process proceso;

    try {
      proceso = await Process.start(
        comandoPython,
        ['-u', 'src/main.py'],
        workingDirectory: rutaProyecto,
        runInShell: true,
        environment: {'PYTHONUNBUFFERED': '1', 'PYTHONIOENCODING': 'utf-8',},
      );
    } catch (e) {
      controller.add('No se pudo iniciar "$comandoPython".');
      controller.add('Detalle: $e');
      unawaited(controller.close());
      return EjecucionPython(
        lineas: controller.stream,
        codigoSalida: Future.value(-1),
        cancelar: () {},
      );
    }

    final stdoutListo = proceso.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach(controller.add);
    final stderrListo = proceso.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach(controller.add);

    final codigoSalida = Future.wait([stdoutListo, stderrListo])
        .then((_) => proceso.exitCode)
        .then((codigo) {
      controller.close();
      return codigo;
    });

    return EjecucionPython(
      lineas: controller.stream,
      codigoSalida: codigoSalida,
      cancelar: () => proceso.kill(),
    );
  }
}