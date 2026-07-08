import 'package:flutter/material.dart';
import '/theme/app_colors.dart';
import '/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String rutaProyecto;
  const ChatScreen({super.key, required this.rutaProyecto});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatService _chatService = ChatService(widget.rutaProyecto);
  final List<ChatMessage> _mensajes = [];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _cargando = false;
  bool _verificandoKey = true;
  bool _tieneKey = false;

  @override
  void initState() {
    super.initState();
    _verificarKey();
  }

  Future<void> _verificarKey() async {
    final ok = await _chatService.tieneApiKey();
    if (!mounted) return;
    setState(() {
      _tieneKey = ok;
      _verificandoKey = false;
    });
    if (!ok) _mostrarDialogoApiKey();
  }

  Future<void> _mostrarDialogoApiKey() async {
    final controller = TextEditingController();
    final guardado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.fondoCard,
        title: const Text('Configurar API key de Anthropic', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pega tu API key de Anthropic (console.anthropic.com). '
                  'Se guarda localmente en config/anthropic_api_key.txt.',
              style: TextStyle(color: AppColors.textoSec, fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'sk-ant-...',
                hintStyle: TextStyle(color: AppColors.textoSec),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await _chatService.guardarApiKey(controller.text);
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (guardado == true && mounted) {
      setState(() => _tieneKey = true);
    }
  }

  Future<void> _enviar() async {
    final texto = _input.text.trim();
    if (texto.isEmpty || _cargando) return;

    setState(() {
      _mensajes.add(ChatMessage(rol: 'user', texto: texto));
      _cargando = true;
      _input.clear();
    });
    _scrollAlFinal();

    try {
      final respuesta = await _chatService.preguntar(
        _mensajes.sublist(0, _mensajes.length - 1), // historial previo
        texto,
      );
      setState(() {
        _mensajes.add(ChatMessage(rol: 'assistant', texto: respuesta));
      });
    } catch (e) {
      setState(() {
        _mensajes.add(ChatMessage(rol: 'assistant', texto: 'Error: $e'));
      });
    } finally {
      setState(() => _cargando = false);
      _scrollAlFinal();
    }
  }

  void _scrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_verificandoKey) {
      return const Center(child: CircularProgressIndicator(color: AppColors.amarillo));
    }

    return Scaffold(
      backgroundColor: AppColors.fondoOscuro,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Asistente de Inventario',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Configurar API key',
                    onPressed: _mostrarDialogoApiKey,
                    icon: const Icon(Icons.key_rounded, color: AppColors.amarillo),
                  ),
                ],
              ),
            ),
            if (!_tieneKey)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Configura tu API key para empezar a chatear.',
                  style: TextStyle(color: AppColors.textoSec),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: _mensajes.length,
                itemBuilder: (_, i) => _Burbuja(mensaje: _mensajes[i]),
              ),
            ),
            if (_cargando)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.amarillo),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      enabled: _tieneKey,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (_) => _enviar(),
                      decoration: InputDecoration(
                        hintText: '¿Qué productos hay que reabastecer?',
                        hintStyle: const TextStyle(color: AppColors.textoSec),
                        filled: true,
                        fillColor: AppColors.fondoCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _tieneKey ? _enviar : null,
                    icon: const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(backgroundColor: AppColors.amarillo, foregroundColor: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  final ChatMessage mensaje;
  const _Burbuja({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final esUsuario = mensaje.rol == 'user';
    return Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: esUsuario ? AppColors.amarillo : AppColors.fondoCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          mensaje.texto,
          style: TextStyle(color: esUsuario ? Colors.black : Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}