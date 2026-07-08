import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../producto.dart';

typedef GuardarProductoCallback = void Function({
required String codigo,
required String nombre,
required String categoria,
required int stockActual,
required int stockMinimo,
int? diasParaVencer,
});

class ProductoFormSheet extends StatefulWidget {
  final Producto? existente;
  final GuardarProductoCallback onGuardar;

  const ProductoFormSheet({super.key, this.existente, required this.onGuardar});

  @override
  State<ProductoFormSheet> createState() => _ProductoFormSheetState();
}

class _ProductoFormSheetState extends State<ProductoFormSheet> {
  late final TextEditingController codigoCtrl;
  late final TextEditingController nombreCtrl;
  late final TextEditingController categoriaCtrl;
  late final TextEditingController stockCtrl;
  late final TextEditingController stockMinCtrl;
  late final TextEditingController diasVencerCtrl;

  final _formKey = GlobalKey<FormState>();
  String? _errorGuardado;

  @override
  void initState() {
    super.initState();
    final p = widget.existente;
    codigoCtrl = TextEditingController(text: p?.codigo ?? '');
    nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    categoriaCtrl = TextEditingController(text: p?.categoria ?? '');
    stockCtrl = TextEditingController(text: p?.stockActual.toString() ?? '');
    stockMinCtrl = TextEditingController(text: p?.stockMinimo.toString() ?? '');
    diasVencerCtrl = TextEditingController(text: p?.diasParaVencer?.toString() ?? '');
  }

  @override
  void dispose() {
    codigoCtrl.dispose();
    nombreCtrl.dispose();
    categoriaCtrl.dispose();
    stockCtrl.dispose();
    stockMinCtrl.dispose();
    diasVencerCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorGuardado = null);

    try {
      widget.onGuardar(
        codigo: codigoCtrl.text.trim(),
        nombre: nombreCtrl.text.trim(),
        categoria: categoriaCtrl.text.trim(),
        stockActual: int.parse(stockCtrl.text),
        stockMinimo: int.parse(stockMinCtrl.text),
        diasParaVencer: diasVencerCtrl.text.isEmpty ? null : int.parse(diasVencerCtrl.text),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _errorGuardado = _mensajeError(e));
    }
  }

  String _mensajeError(Object e) {
    final texto = e.toString();
    if (texto.contains('UNIQUE') || texto.contains('PRIMARY KEY') || texto.contains('constraint')) {
      return 'Ya existe un producto con el código "${codigoCtrl.text.trim()}". Usa otro código.';
    }
    return 'No se pudo guardar el producto: $texto';
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.existente != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.fondoCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppColors.borde),
            left: BorderSide(color: AppColors.borde),
            right: BorderSide(color: AppColors.borde),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.borde,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Text(
                  esEdicion ? 'Editar producto' : 'Nuevo producto',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textoPri,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  esEdicion
                      ? 'Actualiza los datos de ${widget.existente!.nombre}'
                      : 'Completa los datos para agregarlo al inventario',
                  style: const TextStyle(fontSize: 13, color: AppColors.textoSec),
                ),
                const SizedBox(height: 20),
                if (_errorGuardado != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withOpacity(0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorGuardado!,
                            style: TextStyle(color: AppColors.error, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextFormField(
                  controller: codigoCtrl,
                  enabled: !esEdicion,
                  decoration: const InputDecoration(labelText: 'Código de producto'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: categoriaCtrl,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Stock actual'),
                        validator: (v) => (v == null || int.tryParse(v) == null) ? 'Inválido' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: stockMinCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Stock mínimo'),
                        validator: (v) => (v == null || int.tryParse(v) == null) ? 'Inválido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: diasVencerCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Días para vencer (opcional)'),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.borde),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar', style: TextStyle(color: AppColors.textoSec)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.gradienteAccent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _guardar,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Center(
                                child: Text(
                                  esEdicion ? 'Guardar cambios' : 'Agregar producto',
                                  style: const TextStyle(
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}