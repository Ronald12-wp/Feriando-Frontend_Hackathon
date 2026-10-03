import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_colors.dart';
import '../catalogo/catalogo_screen.dart';
import '../chat/chats_screen.dart';
import '../productos/mis_productos_screen.dart';
import '../trueques/trueques_screen.dart';
import '../perfil/perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indice = 0;

  final _pantallas = [
    const CatalogoScreen(),
    const MisProductosScreen(),
    const TruequesScreen(),
    const ChatsScreen(),
    const PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final mensajesNoLeidos = context.watch<ChatProvider>().mensajesNoLeidos;
    return Scaffold(
      body: IndexedStack(index: _indice, children: _pantallas),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indice,
        onTap: (i) => setState(() => _indice = i),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.storefront_outlined), activeIcon: const Icon(Icons.storefront), label: lang.translate('home_catalog')),
          BottomNavigationBarItem(icon: const Icon(Icons.inventory_2_outlined), activeIcon: const Icon(Icons.inventory_2), label: lang.translate('home_my_products')),
          BottomNavigationBarItem(icon: const Icon(Icons.sync_alt_outlined), activeIcon: const Icon(Icons.sync_alt), label: lang.translate('home_trades')),
          BottomNavigationBarItem(
            icon: _iconoChat(Icons.chat_bubble_outline, mensajesNoLeidos),
            activeIcon: _iconoChat(Icons.chat_bubble, mensajesNoLeidos),
            label: lang.translate('home_chats'),
          ),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline), activeIcon: const Icon(Icons.person), label: lang.translate('home_profile')),
        ],
      ),
    );
  }

  Widget _iconoChat(IconData icono, int noLeidos) {
    return SizedBox(
      width: 30,
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(child: Icon(icono)),
          if (noLeidos > 0)
            Positioned(
              top: -6,
              right: -9,
              child: Container(
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: const BoxDecoration(
                  color: AppColors.insigniaNoLeido,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  noLeidos > 9 ? '9+' : '$noLeidos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
