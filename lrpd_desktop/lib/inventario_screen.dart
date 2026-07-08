import 'package:flutter/material.dart';
import 'db_service.dart';
import 'producto.dart';
import 'theme/app_colors.dart';
import 'widgets/producto_card.dart';
import 'widgets/producto_form_sheet.dart';

class InventarioScreen extends StatefulWidget {
  final DBService dbService;
  const InventarioScreen({super.key, required this.dbService});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  List<Producto> _productos = [];
  String _busqueda = '';
  String _categoriaSeleccionada = 'Todas';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    setState(() {
      _productos = widget.dbService.obtenerProductos().map((m) => Producto.fromMap(m)).toList();
    });
  }

  List<String> get _categorias {
    final set = _productos.map((p) => p.categoria).where((c) => c.isNotEmpty).toSet().toList();
    set.sort();
    return ['Todas', ...set];
  }

  List<Producto> get _productosFiltrados {
    return _productos.where((p) {
      final coincideBusqueda = _busqueda.isEmpty ||
          p.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
          p.codigo.toLowerCase().contains(_busqueda.toLowerCase());
      final coincideCategoria = _categoriaSeleccionada == 'Todas' || p.categoria == _categoriaSeleccionada;
      return coincideBusqueda && coincideCategoria;
    }).toList();
  }

  void _abrirFormulario({Producto? existente}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductoFormSheet(
        existente: existente,
        onGuardar: ({
          required String codigo,
          required String nombre,
          required String categoria,
          required int stockActual,
          required int stockMinimo,
          int? diasParaVencer,
        }) {
          if (existente == null) {
            widget.dbService.agregarProducto(
              codigo: codigo,
              nombre: nombre,
              categoria: categoria,
              stockActual: stockActual,
              stockMinimo: stockMinimo,
              diasParaVencer: diasParaVencer,
            );
          } else {
            widget.dbService.actualizarProducto(
              codigo: codigo,
              nombre: nombre,
              categoria: categoria,
              stockActual: stockActual,
              stockMinimo: stockMinimo,
              diasParaVencer: diasParaVencer,
            );
          }
          _cargar();
        },
      ),
    );
  }

  void _confirmarEliminar(Producto p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.fondoCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Eliminar producto', style: TextStyle(color: AppColors.textoPri)),
        content: Text(
          '¿Seguro que quieres eliminar "${p.nombre}" del inventario?',
          style: const TextStyle(color: AppColors.textoSec),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textoSec)),
          ),
          TextButton(
            onPressed: () {
              widget.dbService.eliminarProducto(p.codigo);
              Navigator.pop(context);
              _cargar();
            },
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _productosFiltrados;
    final bajoStock = _productos.where((p) => p.nivelStock != NivelStock.saludable).length;

    return Scaffold(
      backgroundColor: AppColors.fondoOscuro,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.gradienteAccent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: AppColors.naranja.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _abrirFormulario(),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: AppColors.fondoOscuro),
                  SizedBox(width: 8),
                  Text('Nuevo producto', style: TextStyle(color: AppColors.fondoOscuro, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => AppColors.gradienteAccent.createShader(bounds),
                    child: const Text(
                      'Inventario',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatPill(icono: Icons.inventory_2_outlined, texto: '${_productos.length} productos'),
                      const SizedBox(width: 8),
                      if (bajoStock > 0)
                        _StatPill(
                          icono: Icons.warning_amber_rounded,
                          texto: '$bajoStock con stock bajo',
                          color: AppColors.naranja,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                style: const TextStyle(color: AppColors.textoPri),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o código...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textoSec, size: 20),
                ),
                onChanged: (v) => setState(() => _busqueda = v),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _categorias.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categorias[i];
                  final seleccionada = cat == _categoriaSeleccionada;
                  return GestureDetector(
                    onTap: () => setState(() => _categoriaSeleccionada = cat),
                    child: AnimatedContainer(
                      duration: AppColors.dFast,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: seleccionada ? AppColors.amberBg : AppColors.fondoField,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: seleccionada ? AppColors.naranja : AppColors.borde),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: seleccionada ? AppColors.amarillo : AppColors.textoSec,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtrados.isEmpty
                  ? _EstadoVacio(mostrandoBusqueda: _busqueda.isNotEmpty || _categoriaSeleccionada != 'Todas')
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                itemCount: filtrados.length,
                itemBuilder: (_, i) {
                  final p = filtrados[i];
                  return ProductoCard(
                    producto: p,
                    onEditar: () => _abrirFormulario(existente: p),
                    onEliminar: () => _confirmarEliminar(p),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color? color;

  const _StatPill({required this.icono, required this.texto, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textoSec;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.fondoCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: c),
          const SizedBox(width: 6),
          Text(texto, style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  final bool mostrandoBusqueda;
  const _EstadoVacio({required this.mostrandoBusqueda});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            mostrandoBusqueda ? Icons.search_off : Icons.inventory_2_outlined,
            size: 48,
            color: AppColors.textoMuted,
          ),
          const SizedBox(height: 12),
          Text(
            mostrandoBusqueda ? 'No se encontraron productos' : 'Aún no hay productos',
            style: const TextStyle(color: AppColors.textoSec, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            mostrandoBusqueda ? 'Prueba con otro término de búsqueda' : 'Agrega el primero con el botón de abajo',
            style: const TextStyle(color: AppColors.textoMuted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}