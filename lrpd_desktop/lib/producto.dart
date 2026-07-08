enum NivelStock { saludable, alerta, critico }

class Producto {
  final String codigo;
  final String nombre;
  final String categoria;
  final int stockActual;
  final int stockMinimo;
  final int? diasParaVencer;

  Producto({
    required this.codigo,
    required this.nombre,
    required this.categoria,
    required this.stockActual,
    required this.stockMinimo,
    this.diasParaVencer,
  });

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      codigo: map['codigo_producto'] as String,
      nombre: map['nombre_producto'] as String,
      categoria: (map['categoria'] as String?) ?? '',
      stockActual: map['stock_actual'] as int,
      stockMinimo: map['stock_minimo'] as int,
      diasParaVencer: map['dias_para_vencer'] as int?,
    );
  }

  NivelStock get nivelStock {
    if (stockActual <= stockMinimo) return NivelStock.critico;
    if (stockActual <= stockMinimo * 1.5) return NivelStock.alerta;
    return NivelStock.saludable;
  }

  /// Proporción 0.0–1.0 usada para el indicador visual de stock.
  double get proporcionStock {
    final referencia = stockMinimo > 0 ? stockMinimo * 2 : 10;
    return (stockActual / referencia).clamp(0.0, 1.0);
  }
}