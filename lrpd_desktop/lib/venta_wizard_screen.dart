import 'package:flutter/material.dart';
import 'db_service.dart';
import 'producto.dart';
import 'theme/app_colors.dart';

enum FormaPago { efectivo, tarjeta, yapePlin }

extension FormaPagoX on FormaPago {
  String get etiqueta {
    switch (this) {
      case FormaPago.efectivo: return 'Efectivo';
      case FormaPago.tarjeta: return 'Tarjeta';
      case FormaPago.yapePlin: return 'Yape / Plin';
    }
  }

  String get valorDb {
    switch (this) {
      case FormaPago.efectivo: return 'efectivo';
      case FormaPago.tarjeta: return 'tarjeta';
      case FormaPago.yapePlin: return 'yape_plin';
    }
  }

  IconData get icono {
    switch (this) {
      case FormaPago.efectivo: return Icons.payments_outlined;
      case FormaPago.tarjeta: return Icons.credit_card;
      case FormaPago.yapePlin: return Icons.qr_code_2;
    }
  }
}

class VentaWizardScreen extends StatefulWidget {
  final DBService dbService;
  final List<Producto> productos;

  const VentaWizardScreen({super.key, required this.dbService, required this.productos});

  @override
  State<VentaWizardScreen> createState() => _VentaWizardScreenState();
}

class _VentaWizardScreenState extends State<VentaWizardScreen> {
  int _paso = 0;
  String? _codigoSeleccionado;
  int _cantidad = 1;
  FormaPago _formaPago = FormaPago.efectivo;

  Producto? get _producto {
    if (_codigoSeleccionado == null) return null;
    try {
      return widget.productos.firstWhere((p) => p.codigo == _codigoSeleccionado);
    } catch (_) {
      return null;
    }
  }

  void _confirmarVenta() {
    widget.dbService.registrarVenta(_codigoSeleccionado!, _cantidad, formaPago: _formaPago.valorDb);
    setState(() => _paso = 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoOscuro,
      appBar: AppBar(
        backgroundColor: AppColors.fondoOscuro,
        elevation: 0,
        leading: _paso < 2
            ? IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
            : null,
        title: Text(['Producto y cantidad', 'Forma de pago', 'Venta registrada'][_paso]),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _IndicadorPasos(pasoActual: _paso),
              const SizedBox(height: 24),
              Expanded(
                child: switch (_paso) {
                  0 => _PasoProducto(
                    productos: widget.productos,
                    codigoSeleccionado: _codigoSeleccionado,
                    cantidad: _cantidad,
                    onProducto: (v) => setState(() => _codigoSeleccionado = v),
                    onCantidad: (v) => setState(() => _cantidad = v),
                  ),
                  1 => _PasoPago(
                    producto: _producto!,
                    cantidad: _cantidad,
                    formaPago: _formaPago,
                    onFormaPago: (v) => setState(() => _formaPago = v),
                  ),
                  _ => _PasoExito(
                    producto: _producto!,
                    cantidad: _cantidad,
                    formaPago: _formaPago,
                  ),
                },
              ),
              const SizedBox(height: 16),
              _BotonesNavegacion(
                paso: _paso,
                puedeAvanzar: _paso == 0 ? _codigoSeleccionado != null : true,
                onAtras: () => setState(() => _paso -= 1),
                onSiguiente: () {
                  if (_paso == 0) setState(() => _paso = 1);
                  if (_paso == 1) _confirmarVenta();
                },
                onFinalizar: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IndicadorPasos extends StatelessWidget {
  final int pasoActual;
  const _IndicadorPasos({required this.pasoActual});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final activo = i <= pasoActual;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
            decoration: BoxDecoration(
              color: activo ? AppColors.naranja : AppColors.fondoField,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

class _PasoProducto extends StatelessWidget {
  final List<Producto> productos;
  final String? codigoSeleccionado;
  final int cantidad;
  final ValueChanged<String?> onProducto;
  final ValueChanged<int> onCantidad;

  const _PasoProducto({
    required this.productos,
    required this.codigoSeleccionado,
    required this.cantidad,
    required this.onProducto,
    required this.onCantidad,
  });

  @override
  Widget build(BuildContext context) {
    final producto = productos.where((p) => p.codigo == codigoSeleccionado).firstOrNull;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Producto', style: TextStyle(color: AppColors.textoSec, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: codigoSeleccionado,
            dropdownColor: AppColors.fondoField,
            style: const TextStyle(color: AppColors.textoPri, fontSize: 14),
            decoration: const InputDecoration(hintText: 'Selecciona un producto'),
            items: productos.map((p) {
              return DropdownMenuItem(value: p.codigo, child: Text('${p.nombre} · stock: ${p.stockActual}'));
            }).toList(),
            onChanged: onProducto,
          ),
          const SizedBox(height: 24),
          if (producto != null) ...[
            const Text('Cantidad', style: TextStyle(color: AppColors.textoSec, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.fondoCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borde),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.textoSec),
                    onPressed: cantidad > 1 ? () => onCantidad(cantidad - 1) : null,
                  ),
                  Expanded(
                    child: Text('$cantidad', textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textoPri)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.amarillo),
                    onPressed: cantidad < producto.stockActual ? () => onCantidad(cantidad + 1) : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('Disponible: ${producto.stockActual} unidades', style: const TextStyle(fontSize: 12, color: AppColors.textoMuted)),
          ],
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _PasoPago extends StatelessWidget {
  final Producto producto;
  final int cantidad;
  final FormaPago formaPago;
  final ValueChanged<FormaPago> onFormaPago;

  const _PasoPago({
    required this.producto,
    required this.cantidad,
    required this.formaPago,
    required this.onFormaPago,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.fondoCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borde),
          ),
          child: Row(
            children: [
              const Icon(Icons.shopping_bag_outlined, color: AppColors.naranja),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(producto.nombre, style: const TextStyle(color: AppColors.textoPri, fontWeight: FontWeight.w700)),
                    Text('Cantidad: $cantidad', style: const TextStyle(color: AppColors.textoSec, fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Forma de pago', style: TextStyle(color: AppColors.textoSec, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ...FormaPago.values.map((f) {
          final seleccionada = f == formaPago;
          return GestureDetector(
            onTap: () => onFormaPago(f),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: seleccionada ? AppColors.amberBg : AppColors.fondoCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: seleccionada ? AppColors.naranja : AppColors.borde),
              ),
              child: Row(
                children: [
                  Icon(f.icono, color: seleccionada ? AppColors.amarillo : AppColors.textoSec),
                  const SizedBox(width: 12),
                  Text(f.etiqueta, style: TextStyle(
                    color: seleccionada ? AppColors.textoPri : AppColors.textoSec,
                    fontWeight: seleccionada ? FontWeight.w700 : FontWeight.w500,
                  )),
                  const Spacer(),
                  if (seleccionada) const Icon(Icons.check_circle, color: AppColors.amarillo, size: 20),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _PasoExito extends StatelessWidget {
  final Producto producto;
  final int cantidad;
  final FormaPago formaPago;

  const _PasoExito({required this.producto, required this.cantidad, required this.formaPago});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (_, valor, hijo) => Transform.scale(scale: valor, child: hijo),
            child: Container(
              width: 84, height: 84,
              decoration: const BoxDecoration(color: AppColors.exitoBg, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: AppColors.exito, size: 48),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Venta exitosa', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textoPri)),
          const SizedBox(height: 6),
          Text('${cantidad}x ${producto.nombre}', style: const TextStyle(color: AppColors.textoSec)),
          Text('Pagado con ${formaPago.etiqueta}', style: const TextStyle(color: AppColors.textoMuted, fontSize: 12.5)),
        ],
      ),
    );
  }
}

class _BotonesNavegacion extends StatelessWidget {
  final int paso;
  final bool puedeAvanzar;
  final VoidCallback onAtras;
  final VoidCallback onSiguiente;
  final VoidCallback onFinalizar;

  const _BotonesNavegacion({
    required this.paso,
    required this.puedeAvanzar,
    required this.onAtras,
    required this.onSiguiente,
    required this.onFinalizar,
  });

  @override
  Widget build(BuildContext context) {
    if (paso == 2) {
      return SizedBox(
        width: double.infinity,
        child: _BotonGradiente(texto: 'Volver a ventas', onTap: onFinalizar),
      );
    }

    return Row(
      children: [
        if (paso == 1)
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borde),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onAtras,
              child: const Text('Atrás', style: TextStyle(color: AppColors.textoSec)),
            ),
          ),
        if (paso == 1) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _BotonGradiente(
            texto: paso == 0 ? 'Continuar' : 'Confirmar venta',
            onTap: puedeAvanzar ? onSiguiente : null,
          ),
        ),
      ],
    );
  }
}

class _BotonGradiente extends StatelessWidget {
  final String texto;
  final VoidCallback? onTap;
  const _BotonGradiente({required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activo = onTap != null;
    return Container(
      decoration: BoxDecoration(
        gradient: activo ? AppColors.gradienteAccent : null,
        color: activo ? null : AppColors.fondoField,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(texto, style: TextStyle(
                color: activo ? AppColors.fondoOscuro : AppColors.textoMuted,
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
              )),
            ),
          ),
        ),
      ),
    );
  }
}