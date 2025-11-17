import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import './models/usuario_logado.dart';

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  // ignore: unused_field
  int _navIndex = 0;
  int _notificationCount = 5;

  UsuarioLogado? usuario; // usuário logado
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _carregarUsuarioLogado();
  }

  // Carrega o usuário logado e a foto
  Future<void> _carregarUsuarioLogado() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() => loading = false);
        debugPrint("Nenhum token encontrado.");
        return;
      }

      // 1️⃣ Pega os dados do usuário
      final response = await http.get(
        Uri.parse('http://192.168.0.22:5000/usuario_logado'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'ok' && data['usuario'] != null) {
          setState(() {
            usuario = UsuarioLogado.fromJson(data['usuario']);
          });

          // 2️⃣ Busca a foto atualizada do usuário
          await _carregarFotoUsuario(usuario!.idUsuario);
        } else {
          debugPrint("Erro ao carregar usuário: ${data['mensagem']}");
        }
      } else if (response.statusCode == 401) {
        debugPrint("Token inválido ou expirado.");
      } else {
        debugPrint("Erro ao carregar usuário: ${response.body}");
      }
    } catch (e) {
      debugPrint("Erro ao carregar usuário: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  // Busca a foto atualizada do usuário
  Future<void> _carregarFotoUsuario(int idUsuario) async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.22:5000/usuario/$idUsuario/foto'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok' && data['foto'] != null) {
          setState(() {
            usuario!.foto = data['foto']; // atualiza a foto do usuário
          });
        }
      } else {
        debugPrint("Erro ao carregar foto: ${response.body}");
      }
    } catch (e) {
      debugPrint("Erro ao carregar foto: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFFD32F2F);
    final ColorScheme cs = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: const Color(0xFFFF5252),
      surface: const Color(0xFFF9F9F9),
      primaryContainer: const Color(0xFFFFCDD2),
      onPrimaryContainer: Colors.black87,
    );

    return Theme(
      data: ThemeData(colorScheme: cs, useMaterial3: true),
      child: Scaffold(
        backgroundColor: cs.surface,
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 180,
                    backgroundColor: cs.primary,
                    elevation: 0,
                    shape: const ContinuousRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: _HeaderGradient(
                        colorScheme: cs,
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 16,
                              end: 16,
                              top: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundImage: usuario?.foto != null
                                          ? MemoryImage(
                                              base64Decode(usuario!.foto!),
                                            )
                                          : const AssetImage(
                                                  'assets/images/foto_perfil_teste.png',
                                                )
                                                as ImageProvider,
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Conta: ${usuario?.cargo ?? "Desconhecido"}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Colors.white.withOpacity(
                                                  .9,
                                                ),
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: .2,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Olá, ${usuario?.nomeUsuario ?? "Usuário"}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    _NotificationButton(
                                      count: _notificationCount,
                                      onTap: () {
                                        setState(() {
                                          _notificationCount = 0;
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    Image.asset(
                                      'assets/images/logo.png',
                                      height: 44,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _WelcomeCard(
                            colorScheme: cs,
                            title: 'Bem-vindo ao APP Ademicon.',
                            subtitle:
                                'Você tem $_notificationCount notificações de seus LEADS',
                            onNotifications: () {
                              debugPrint('Abrir notificações');
                            },
                          ),
                          const SizedBox(height: 30),
                          _ActionsGrid(
                            items: [
                              ActionItem(
                                icon: Icons.search_rounded,
                                label: 'Buscar Leads',
                                onTap: () => Navigator.of(
                                  context,
                                ).pushNamed('/buscar_leads'),
                              ),
                              ActionItem(
                                icon: Icons.add_circle_rounded,
                                label: 'Criar Leads',
                                onTap: () =>
                                    Navigator.of(context).pushNamed('/leads'),
                              ),
                              ActionItem(
                                icon: Icons.groups_rounded,
                                label: 'Meus Leads',
                                onTap: () => Navigator.of(
                                  context,
                                ).pushNamed('/meus_leads'),
                              ),
                              ActionItem(
                                icon: Icons.bookmark_rounded,
                                label: 'Leads Salvos',
                                onTap: () => debugPrint('Leads Salvos'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Header com gradiente
class _HeaderGradient extends StatelessWidget {
  final Widget child;
  final ColorScheme colorScheme;
  const _HeaderGradient({required this.child, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.85),
            const Color(0xFFB71C1C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.08),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Botão de sino com badge
class _NotificationButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _NotificationButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
          ),
          tooltip: 'Notificações',
        ),
        if (count > 0)
          Positioned(right: 4, top: 6, child: _Badge(count: count)),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    final display = count > 99 ? '99+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        display,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: .2,
        ),
      ),
    );
  }
}

/// Card de boas-vindas
class _WelcomeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onNotifications;
  final ColorScheme colorScheme;

  const _WelcomeCard({
    required this.title,
    required this.subtitle,
    required this.onNotifications,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withOpacity(.92),
            colorScheme.primaryContainer.withOpacity(.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(.16), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87.withOpacity(.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          IconButton(
            onPressed: onNotifications,
            icon: const Icon(Icons.notifications),
            color: Colors.black87,
          ),
        ],
      ),
    );
  }
}

/// Grid de ações
class _ActionsGrid extends StatelessWidget {
  final List<ActionItem> items;
  const _ActionsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: items
          .map(
            (item) => GestureDetector(
              onTap: item.onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 36, color: const Color(0xFFD32F2F)),
                    const SizedBox(height: 12),
                    Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  ActionItem({required this.icon, required this.label, required this.onTap});
}
