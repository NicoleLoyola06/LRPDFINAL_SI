import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../producto.dart';

class ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const ProductoCard({
    super.key,
    required this.producto,
    required this.onEditar,
    required this.onEliminar,
  });

  Color get _colorNivel {
    switch (producto.nivelStock) {
      case NivelStock.critico:
        return AppColors.error;
      case NivelStock.alerta:
        return AppColors.naranja;
      case NivelStock.saludable:
        return AppColors.exito;
    }
  }

  String get _etiquetaNivel {
    switch (producto.nivelStock) {
      case NivelStock.critico:
        return 'Stock crítico';
      case NivelStock.alerta:
        return 'Stock bajo';
      case NivelStock.saludable:
        return 'Stock saludable';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.fondoCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borde),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onEditar,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 54,
                  decoration: BoxDecoration(
                    color: _colorNivel,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              producto.nombre,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textoPri,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            producto.codigo.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                              color: AppColors.textoMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.fondoField,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              producto.categoria.isEmpty ? 'Sin categoría' : producto.categoria,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textoSec,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (producto.diasParaVencer != null)
                            Text(
                              'Vence en ${producto.diasParaVencer} días',
                              style: const TextStyle(fontSize: 11, color: AppColors.textoMuted),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Stack(
                          children: [
                            Container(height: 6, width: double.infinity, color: AppColors.fondoField),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return TweenAnimationBuilder<double>(
                                  duration: AppColors.dMed,
                                  curve: Curves.easeOut,
                                  tween: Tween(begin: 0, end: producto.proporcionStock),
                                  builder: (context, value, _) {
                                    return Container(
                                      height: 6,
                                      width: constraints.maxWidth * value,
                                      color: _colorNivel,
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '${producto.stockActual} uds',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textoPri,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '· mín. ${producto.stockMinimo} · $_etiquetaNivel',
                            style: TextStyle(fontSize: 11.5, color: _colorNivel, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Column(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.edit_outlined, size: 19, color: AppColors.textoSec),
                      onPressed: onEditar,
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline, size: 19, color: AppColors.textoMuted),
                      onPressed: onEliminar,
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