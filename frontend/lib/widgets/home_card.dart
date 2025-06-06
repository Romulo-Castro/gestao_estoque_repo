// lib/widgets/home_card.dart
import 'package:flutter/material.dart';

class HomeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final String? subtitle; // Opcional: para mostrar contagem, etc.
  final Color? iconColor; // Opcional: Cor do ícone
  final int? count; // Contador para exibir abaixo do título
  final bool isLoading; // Para mostrar loading no contador

  const HomeCard({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
    this.subtitle,
    this.iconColor,
    this.count,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2.0,
      // Usar cor ligeiramente diferente do fundo do scaffold
      color: theme.scaffoldBackgroundColor == Colors.black ? Colors.grey[850] : Colors.white,
      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // Opcional
      child: InkWell( // Para efeito de toque
        onTap: onTap,
        borderRadius: BorderRadius.circular(4.0), // Mesmo raio do Card padrão
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 40.0,
                // Usa cor passada, cor primária ou cor padrão de ícone
                color: iconColor ?? colorScheme.primary,
              ),
              const SizedBox(height: 12.0),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  // Ajusta cor do texto baseado no fundo do card
                  color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87
                ),              ),
              if (count != null) ...[
                const SizedBox(height: 8.0),
                isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: iconColor ?? colorScheme.primary,
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: (iconColor ?? colorScheme.primary).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          count.toString(),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: iconColor ?? colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ],
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                 const SizedBox(height: 4.0),
                 Text(
                   subtitle!,
                   textAlign: TextAlign.center,
                   style: theme.textTheme.bodySmall?.copyWith(
                       color: theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600]
                   ),
                 ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}