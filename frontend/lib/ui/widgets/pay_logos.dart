import 'package:flutter/material.dart';

import '../../data/models/models.dart';

/// Provider logo fetched from the network, falling back to a coloured label
/// when offline or the image fails to load.
class PayLogo extends StatelessWidget {
  const PayLogo(this.method, {super.key, this.height = 34});

  final PaymentMethod method;
  final double height;

  @override
  Widget build(BuildContext context) {
    final url = switch (method) {
      PaymentMethod.momo => 'https://api.companyenrich.com/logo/mtn.com',
      PaymentMethod.orange => 'https://api.companyenrich.com/logo/orange.com',
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        url,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _Fallback(method: method, height: height),
        loadingBuilder: (_, child, progress) => progress == null ? child : SizedBox(height: height, width: height),
      ),
    );
  }
}

/// Offline brand mark (MTN yellow / Orange square) for compact places such
/// as receipts, where a network logo would leave a blank tile.
class PayMark extends StatelessWidget {
  const PayMark(this.method, {super.key, this.size = 40});

  final PaymentMethod method;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (method) {
      PaymentMethod.momo => (const Color(0xFFFFCC00), const Color(0xFF004F71), 'MTN'),
      PaymentMethod.orange => (const Color(0xFFFF7900), Colors.white, 'OM'),
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: size >= 30
            ? [BoxShadow(color: bg.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: size * 0.3,
          fontWeight: FontWeight.w900,
          letterSpacing: size >= 30 ? 0.5 : 0,
          color: fg,
          height: 1,
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.method, required this.height});

  final PaymentMethod method;
  final double height;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (method) {
      PaymentMethod.momo => (const Color(0xFFFFCC00), const Color(0xFF1B1B1B)),
      PaymentMethod.orange => (const Color(0xFFFF7900), Colors.white),
    };
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      color: bg,
      child: Text(
        method.label,
        style: TextStyle(fontSize: height < 30 ? 10 : 13, fontWeight: FontWeight.w800, letterSpacing: 0.3, color: fg),
      ),
    );
  }
}
