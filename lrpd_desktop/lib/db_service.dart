import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';

class DBService {
  late Database db;

  DBService(String dbPath) {
    final archivo = File(dbPath);
    if (!archivo.parent.existsSync()) {
      archivo.parent.createSync(recursive: true);
    }

    db = sqlite3.open(dbPath);
    _crearTablas();
    _migrarColumnaFormaPago();
    _crearTablaUsuarios();
  }

  void _crearTablas() {
    db.execute('''
      CREATE TABLE IF NOT EXISTS inventario (
        codigo_producto TEXT PRIMARY KEY,
        nombre_producto TEXT NOT NULL,
        categoria TEXT,
        stock_actual INTEGER NOT NULL DEFAULT 0,
        stock_minimo INTEGER NOT NULL DEFAULT 0,
        dias_para_vencer INTEGER
      )
    ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo_producto TEXT NOT NULL,
        fecha DATE NOT NULL,
        cantidad_vendida INTEGER NOT NULL,
        origen TEXT DEFAULT 'real',
        FOREIGN KEY (codigo_producto) REFERENCES inventario(codigo_producto)
      )
    ''');
  }

  /// Agrega forma_pago a bases de datos que ya existían sin esa columna.
  void _migrarColumnaFormaPago() {
    try {
      db.execute("ALTER TABLE ventas ADD COLUMN forma_pago TEXT DEFAULT 'efectivo'");
    } catch (_) {
      // La columna ya existe, no hacemos nada.
    }
  }

  void _crearTablaUsuarios() {
    db.execute('''
      CREATE TABLE IF NOT EXISTS usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        nombre_completo TEXT
      )
    ''');

    final count = db.select("SELECT COUNT(*) as c FROM usuarios").first['c'] as int;
    if (count == 0) {
      db.execute(
        "INSERT INTO usuarios (usuario, password_hash, nombre_completo) VALUES (?, ?, ?)",
        ['admin', _hashPassword('admin123'), 'Administrador'],
      );
    }
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  bool validarLogin(String usuario, String password) {
    final resultado = db.select("SELECT * FROM usuarios WHERE usuario = ?", [usuario]);
    if (resultado.isEmpty) return false;
    return resultado.first['password_hash'] == _hashPassword(password);
  }

  // ---------- INVENTARIO (igual que antes) ----------

  List<Map<String, dynamic>> obtenerProductos() {
    return db.select("SELECT * FROM inventario ORDER BY nombre_producto").toList();
  }

  void agregarProducto({
    required String codigo,
    required String nombre,
    required String categoria,
    required int stockActual,
    required int stockMinimo,
    int? diasParaVencer,
  }) {
    db.execute(
      '''INSERT INTO inventario
         (codigo_producto, nombre_producto, categoria, stock_actual, stock_minimo, dias_para_vencer)
         VALUES (?, ?, ?, ?, ?, ?)''',
      [codigo, nombre, categoria, stockActual, stockMinimo, diasParaVencer],
    );
  }

  void actualizarProducto({
    required String codigo,
    required String nombre,
    required String categoria,
    required int stockActual,
    required int stockMinimo,
    int? diasParaVencer,
  }) {
    db.execute(
      '''UPDATE inventario SET
         nombre_producto = ?, categoria = ?, stock_actual = ?,
         stock_minimo = ?, dias_para_vencer = ?
         WHERE codigo_producto = ?''',
      [nombre, categoria, stockActual, stockMinimo, diasParaVencer, codigo],
    );
  }

  void eliminarProducto(String codigo) {
    db.execute("DELETE FROM inventario WHERE codigo_producto = ?", [codigo]);
  }

  // ---------- VENTAS ----------

  void registrarVenta(String codigoProducto, int cantidad, {String formaPago = 'efectivo'}) {
    final fecha = DateTime.now().toIso8601String().substring(0, 10);

    db.execute(
      "INSERT INTO ventas (codigo_producto, fecha, cantidad_vendida, origen, forma_pago) VALUES (?, ?, ?, 'real', ?)",
      [codigoProducto, fecha, cantidad, formaPago],
    );

    db.execute(
      "UPDATE inventario SET stock_actual = stock_actual - ? WHERE codigo_producto = ?",
      [cantidad, codigoProducto],
    );
  }

  List<Map<String, dynamic>> obtenerVentasRecientes({int limite = 50}) {
    return db.select(
      "SELECT v.*, i.nombre_producto FROM ventas v "
          "JOIN inventario i ON v.codigo_producto = i.codigo_producto "
          "ORDER BY v.fecha DESC, v.id DESC LIMIT ?",
      [limite],
    ).toList();
  }

  void close() => db.dispose();
}