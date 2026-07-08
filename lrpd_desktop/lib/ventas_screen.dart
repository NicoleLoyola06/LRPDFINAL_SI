import 'package:flutter/material.dart';
import 'db_service.dart';
import 'producto.dart';
import 'theme/app_colors.dart';
import 'venta_wizard_screen.dart';

class VentasScreen extends StatefulWidget {
  final DBService dbService;
  const VentasScreen({super.key, required this.dbService});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  List<Producto> _productos = [];
  List<Map<String, dynamic>> _ventas = [];
  String? _codigoSeleccionado;
  final _cantidadCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _productos = widget.dbService.obtenerProductos().map((m) => Producto.fromMap(m)).toList();
      _ventas = widget.dbService.obtenerVentasRecientes();
    });
  }

  Producto? get _productoSeleccionado {
    if (_codigoSeleccionado == null) return null;
    try {
      return _productos.firstWhere((p) => p.codigo == _codigoSeleccionado);
    } catch (_) {
      return null;
    }
  }

  void _registrar() {
    if (!_formKey.currentState!.validate() || _codigoSeleccionado == null) return;

    final cantidad = int.parse(_cantidadCtrl.text);
    final producto = _productoSeleccionado;

    if (producto != null && cantidad > producto.stockActual) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay suficiente stock (disponible: ${producto.stockActual})'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    widget.dbService.registrarVenta(_codigoSeleccionado!, cantidad);

    setState(() {
      _cantidadCtrl.clear();
      _codigoSeleccionado = null;
      _cargar();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Venta registrada'), backgroundColor: AppColors.exito),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoOscuro,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            ShaderMask(
              shaderCallback: (bounds) => AppColors.gradienteAccent.createShader(bounds),
              child: const Text(
                'Ventas',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Registra una venta y actualiza el stock al instante',
              style: TextStyle(fontSize: 13, color: AppColors.textoSec),
            ),
            const SizedBox(height: 20),
            // Dentro de _VentasScreenState, reemplaza el widget _FormularioVenta(...) por:

            Container(
              decoration: BoxDecoration(gradient: AppColors.gradienteAccent, borderRadius: BorderRadius.circular(16)),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final resultado = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => VentaWizardScreen(dbService: widget.dbService, productos: _productos)),
                    );
                    if (resultado == true) _cargar();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.point_of_sale, color: AppColors.fondoOscuro),
                          SizedBox(width: 8),
                          Text('Registrar nueva venta', style: TextStyle(color: AppColors.fondoOscuro, fontWeight: FontWeight.w800, fontSize: 14.5)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                const Text(
                  'Ventas recientes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textoPri),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.fondoField,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_ventas.length}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textoSec, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_ventas.isEmpty)
              const _EstadoVaciaVentas()
            else
              ..._ventas.map((v) => _VentaTile(venta: v)),
          ],
        ),
      ),
    );
  }
}

class _FormularioVenta extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<Producto> productos;
  final String? codigoSeleccionado;
  final Producto? productoSeleccionado;
  final TextEditingController cantidadCtrl;
  final ValueChanged<String?> onCambiarProducto;
  final VoidCallback onRegistrar;

  const _FormularioVenta({
    required this.formKey,
    required this.productos,
    required this.codigoSeleccionado,
    required this.productoSeleccionado,
    required this.cantidadCtrl,
    required this.onCambiarProducto,
    required this.onRegistrar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.fondoCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borde),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nueva venta',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textoPri),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: codigoSeleccionado,
              dropdownColor: AppColors.fondoField,
              style: const TextStyle(color: AppColors.textoPri, fontSize: 14),
              decoration: const InputDecoration(labelText: 'Producto'),
              hint: const Text('Selecciona un producto', style: TextStyle(color: AppColors.textoMuted)),
              items: productos.map((p) {
                return DropdownMenuItem(
                  value: p.codigo,
                  child: Text('${p.nombre} · stock: ${p.stockActual}', overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: onCambiarProducto,
              validator: (v) => v == null ? 'Selecciona un producto' : null,
            ),
            if (productoSeleccionado != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.amberBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 15, color: AppColors.amarillo),
                    const SizedBox(width: 8),
                    Text(
                      'Disponible: ${productoSeleccionado!.stockActual} unidades',
                      style: const TextStyle(fontSize: 12, color: AppColors.amarillo, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: cantidadCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textoPri),
              decoration: const InputDecoration(labelText: 'Cantidad vendida'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requerido';
                final n = int.tryParse(v);
                if (n == null || n <= 0) return 'Cantidad inválida';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.gradienteAccent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onRegistrar,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        'Registrar venta',
                        style: TextStyle(
                          color: AppColors.fondoOscuro,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VentaTile extends StatelessWidget {
  final Map<String, dynamic> venta;
  const _VentaTile({required this.venta});

  Color get _colorOrigen {
    switch (venta['origen']) {
      case 'sintetico':
        return AppColors.textoMuted;
      case 'migrado':
        return AppColors.naranja;
      default:
        return AppColors.exito;
    }
  }

  String get _etiquetaOrigen {
    switch (venta['origen']) {
      case 'sintetico':
        return 'Sintético';
      case 'migrado':
        return 'Migrado';
      default:
        return 'Real';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.fondoCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.fondoField,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.textoSec),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${venta['nombre_producto']}',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textoPri),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${venta['fecha']}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textoMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${venta['cantidad_vendida']} uds',
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textoPri),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: _colorOrigen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _etiquetaOrigen,
                  style: TextStyle(fontSize: 9.5, color: _colorOrigen, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EstadoVaciaVentas extends StatelessWidget {
  const _EstadoVaciaVentas();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.point_of_sale_outlined, size: 40, color: AppColors.textoMuted),
          SizedBox(height: 10),
          Text('Aún no hay ventas registradas', style: TextStyle(color: AppColors.textoSec, fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('Registra la primera con el formulario de arriba', style: TextStyle(color: AppColors.textoMuted, fontSize: 12.5)),
        ],
      ),
    );
  }
}