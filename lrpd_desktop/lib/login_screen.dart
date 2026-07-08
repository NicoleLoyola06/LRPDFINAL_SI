import 'package:flutter/material.dart';
import 'db_service.dart';
import 'theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  final DBService dbService;
  final VoidCallback onLoginExitoso;

  const LoginScreen({super.key, required this.dbService, required this.onLoginExitoso});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usuarioCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _error;
  bool _cargando = false;

  void _intentarLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    await Future.delayed(const Duration(milliseconds: 300)); // feedback visual

    final valido = widget.dbService.validarLogin(_usuarioCtrl.text.trim(), _passwordCtrl.text);

    setState(() => _cargando = false);

    if (valido) {
      widget.onLoginExitoso();
    } else {
      setState(() => _error = 'Usuario o contraseña incorrectos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoOscuro,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.fondoCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.borde),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      gradient: AppColors.gradienteAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront, color: AppColors.fondoOscuro, size: 28),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'LRPD',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textoPri, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Supermercado Oriental de Chincha',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: AppColors.textoSec),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _usuarioCtrl,
                    style: const TextStyle(color: AppColors.textoPri),
                    decoration: const InputDecoration(labelText: 'Usuario', prefixIcon: Icon(Icons.person_outline, size: 20)),
                    validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.textoPri),
                    decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline, size: 20)),
                    validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                    onFieldSubmitted: (_) => _intentarLogin(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12.5))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Container(
                    decoration: BoxDecoration(gradient: AppColors.gradienteAccent, borderRadius: BorderRadius.circular(14)),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _cargando ? null : _intentarLogin,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: _cargando
                                ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.fondoOscuro),
                            )
                                : const Text('Iniciar sesión',
                                style: TextStyle(color: AppColors.fondoOscuro, fontWeight: FontWeight.w800, fontSize: 14.5)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Usuario por defecto: admin / admin123',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.textoMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}