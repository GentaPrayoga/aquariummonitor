import 'package:flutter/material.dart';

class ControlCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final String? mode; // AUTO, ON, OFF
  final VoidCallback onToggle;
  final Function(String)? onModeChange;

  const ControlCard({
    super.key,
    required this.title,
    required this.icon,
    required this.isActive,
    this.mode,
    required this.onToggle,
    this.onModeChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isActive 
                ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isActive 
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                size: 28,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Title & Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isActive ? 'Active' : 'Inactive',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isActive ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Mode Selector or Toggle Switch
            if (mode != null && onModeChange != null)
              _buildModeSelector(context)
            else
              Transform.scale(
                scale: 1.1,
                child: Switch(
                  value: isActive,
                  onChanged: (_) => onToggle(),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _getModeColor(mode!).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _getModeColor(mode!)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mode!,
              style: TextStyle(
                color: _getModeColor(mode!),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: _getModeColor(mode!),
              size: 20,
            ),
          ],
        ),
      ),
      onSelected: onModeChange,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'AUTO',
          child: Row(
            children: [
              Icon(Icons.autorenew, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text('AUTO'),
              if (mode == 'AUTO')
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.check, size: 16),
                ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'ON',
          child: Row(
            children: [
              Icon(Icons.power_settings_new, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text('ON'),
              if (mode == 'ON')
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.check, size: 16),
                ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'OFF',
          child: Row(
            children: [
              Icon(Icons.power_off, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              const Text('OFF'),
              if (mode == 'OFF')
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.check, size: 16),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getModeColor(String mode) {
    switch (mode) {
      case 'AUTO':
        return Colors.blue;
      case 'ON':
        return Colors.green;
      case 'OFF':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}