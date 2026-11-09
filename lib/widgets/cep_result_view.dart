import 'package:flutter/material.dart';

import '../models/cep_address.dart';
import '../models/request_state.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// Mostra o resultado da consulta ao WebService conforme o estado:
/// inicial, carregando, sucesso ou erro (com botão para tentar novamente).
class CepResultView extends StatelessWidget {
  final RequestState state;
  final CepAddress? address;
  final String errorMessage;
  final VoidCallback onRetry;

  const CepResultView({
    super.key,
    required this.state,
    required this.address,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case RequestState.initial:
        return const _InfoRow(
          icon: Icons.info_outline,
          color: AppColors.textMuted,
          text: 'Digite o CEP e toque na lupa para preencher o endereço.',
        );
      case RequestState.loading:
        return const Row(
          children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 10),
            Text('Buscando endereço...'),
          ],
        );
      case RequestState.success:
        return AppCard(
          color: AppColors.successSoft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle, color: AppColors.success),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(address?.street ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${address?.neighborhood} • ${address?.city} - ${address?.state}'),
                    Text('CEP ${address?.cep}', style: const TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        );
      case RequestState.error:
        return Row(
          children: [
            Expanded(child: _InfoRow(icon: Icons.error_outline, color: AppColors.danger, text: errorMessage)),
            TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
          ],
        );
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InfoRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: color))),
      ],
    );
  }
}
