import 'package:flutter/material.dart';

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  int _navIndex = 0;
  int _notificationCount = 5;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            backgroundColor: cs.primary,
            elevation: 0,
            // borda inferior arredondada (cara de “barra hero”)
            shape: const ContinuousRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _HeaderGradient(
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
                        // Avatar + textos
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 30,
                              backgroundImage: AssetImage(
                                'assets/images/foto_perfil_teste.png',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Conta : Consultor',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Colors.white.withOpacity(.9),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: .2,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Olá, Xamuel',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Logo + sininho com badge
                        Row(
                          children: [
                            _NotificationButton(
                              count: _notificationCount,
                              onTap: () {
                                // TODO: navegue para tela de notificações
                                setState(() {
                                  // exemplo: zera badge ao abrir
                                  _notificationCount = 0;
                                });
                              },
                            ),
                            const SizedBox(width: 12),
                            Image.asset('assets/images/logo.png', height: 44),
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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WelcomeCard(
                    title: 'Bem-vindo ao APP Ademicon.',
                    subtitle: 'Você tem 5 notificações de seus LEADS',
                    onNotifications: () {
                      // TODO: navegue para notificações
                      debugPrint('Abrir notificações');
                    },
                  ),
                  const SizedBox(height: 20),

                  // Grid de ações
                  _ActionsGrid(
                    items: [
                      ActionItem(
                        icon: Icons.search_rounded,
                        label: 'Buscar Leads',
                        onTap: () {
                          // TODO: Buscar Leads
                          debugPrint('Buscar Leads');
                        },
                      ),
                      ActionItem(
                        icon: Icons.add_circle_rounded,
                        label: 'Criar Leads',
                        onTap: () {
                          // TODO: Criar Leads
                          debugPrint('Criar Leads');
                        },
                      ),
                      ActionItem(
                        icon: Icons.groups_rounded,
                        label: 'Meus Leads',
                        onTap: () {
                          // TODO: Meus Leads
                          debugPrint('Meus Leads');
                        },
                      ),
                      ActionItem(
                        icon: Icons.bookmark_rounded,
                        label: 'Leads Salvos',
                        onTap: () {
                          // TODO: Leads Salvos
                          debugPrint('Leads Salvos');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // NavigationBar (Material 3)
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) {
          setState(() => _navIndex = i);
          // TODO: faça a navegação real conforme seu app
          // ex.: if (i == 1) Navigator.push(...);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Leads',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

/// Fundo do header com gradiente + brilho sutil
class _HeaderGradient extends StatelessWidget {
  final Widget child;
  const _HeaderGradient({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // brilho suave (ornamento)
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

/// Botão de sino com badge (sem dependências externas)
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
        color: Colors.white,
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
          color: Colors.black87,
          fontWeight: FontWeight.w800,
          letterSpacing: .2,
        ),
      ),
    );
  }
}

/// Card de boas-vindas com gradiente/vidro e CTA
class _WelcomeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onNotifications;

  const _WelcomeCard({
    required this.title,
    required this.subtitle,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer.withOpacity(.92),
            cs.primaryContainer.withOpacity(.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(.16), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onPrimaryContainer.withOpacity(.90),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: onNotifications,
                      icon: const Icon(Icons.notifications_rounded),
                      label: const Text('Ver notificações'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: alguma ação secundária (ex.: Dúvidas)
                      },
                      icon: const Icon(Icons.help_outline_rounded),
                      label: const Text('Ajuda'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // logo decorativo
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/logo.png',
              height: 64,
              width: 64,
              fit: BoxFit.contain,
              color: Colors.white.withOpacity(.95),
              colorBlendMode: BlendMode.modulate,
            ),
          ),
        ],
      ),
    );
  }
}

/// Item de ação (ícone + rótulo) em estilo cartão
class ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  ActionItem({required this.icon, required this.label, required this.onTap});
}

class _ActionsGrid extends StatelessWidget {
  final List<ActionItem> items;
  const _ActionsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 480;
    final crossAxisCount = isWide ? 4 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 112, // altura fixa elegante
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        return _ActionCard(item: item);
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  final ActionItem item;
  const _ActionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceVariant.withOpacity(.6),
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, size: 28, color: cs.primary),
              const Spacer(),
              Text(
                item.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
