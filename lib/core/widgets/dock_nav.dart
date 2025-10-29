import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Dock-style bottom navigation similar to Apple Music / App Store.
class DockNav extends StatelessWidget {
  const DockNav({super.key});

  static const _items = <_DockItem>[
    _DockItem(icon: Icons.home_outlined, label: 'Inicio', route: '/home'),
    _DockItem(icon: Icons.edit_note_outlined, label: 'Registro', route: '/registro'),
    _DockItem(icon: Icons.group_outlined, label: 'Gestión', route: '/gestion'),
    _DockItem(icon: Icons.analytics_outlined, label: 'Analítica', route: '/analitica'),
    _DockItem(icon: Icons.person_outline, label: 'Perfil', route: '/perfil'),
  ];

  @override
  Widget build(BuildContext context) {
  final router = GoRouter.of(context);
  final current = Uri.base.path;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 720),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _items.map((it) {
                final selected = current.startsWith(it.route);
                return _DockButton(
                  item: it,
                  selected: selected,
                  onTap: () {
                    if (!selected) router.go(it.route);
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem {
  const _DockItem({required this.icon, required this.label, required this.route});
  final IconData icon;
  final String label;
  final String route;
}

class _DockButton extends StatefulWidget {
  const _DockButton({required this.item, required this.selected, required this.onTap});
  final _DockItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_DockButton> createState() => _DockButtonState();
}

class _DockButtonState extends State<_DockButton> with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _setHover(bool v) {
    setState(() {
      _scale = v ? 1.18 : 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.selected ? Theme.of(context).colorScheme.primary : Theme.of(context).iconTheme.color;

    final child = GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        transform: Matrix4.identity()..scale(_scale, _scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.item.icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(widget.item.label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
          ],
        ),
      ),
    );

    if (kIsWeb || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
      return MouseRegion(
        onEnter: (_) => _setHover(true),
        onExit: (_) => _setHover(false),
        cursor: SystemMouseCursors.click,
        child: child,
      );
    }

    return child;
  }
}
