import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../services/external_actions.dart';
import '../../state/app_state.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/feedback.dart';
import '../widgets/pay_logos.dart';
import '../widgets/pressable.dart';

/// Returns `true` when the payment succeeded and the slip was unlocked.
Future<bool?> showPaymentSheet(BuildContext context, ExamResult result) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xFF0F1F1A).withValues(alpha: 0.55),
    builder: (_) => PaymentSheet(result: result),
  );
}

enum _Step { details, confirm, verifying, success }

class PaymentSheet extends StatefulWidget {
  const PaymentSheet({super.key, required this.result});

  final ExamResult result;

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  static const _confirmWindow = 120;

  late final _phone = TextEditingController(text: context.read<AppState>().user?.phone ?? '');
  PaymentMethod _method = PaymentMethod.momo;
  PaymentMethod? _detected;
  _Step _step = _Step.details;
  String? _txnId;
  Timer? _countdown;
  int _secondsLeft = _confirmWindow;

  bool get _busy => _step == _Step.verifying || _step == _Step.success;

  @override
  void initState() {
    super.initState();
    _detected = PaymentMethod.fromPhone(_phone.text);
    _method = _detected ?? _method;
    _phone.addListener(_detectOperator);
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _phone.dispose();
    super.dispose();
  }

  void _detectOperator() {
    final detected = PaymentMethod.fromPhone(_phone.text);
    if (detected == _detected) return;
    setState(() {
      _detected = detected;
      if (detected != null) _method = detected;
    });
  }

  void _startCountdown() {
    _countdown?.cancel();
    _secondsLeft = _confirmWindow;
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _secondsLeft = (_secondsLeft - 1).clamp(0, _confirmWindow));
      if (_secondsLeft == 0) t.cancel();
    });
  }

  void _continue() {
    final phone = _phone.text.trim();
    if (phone.length < 8) {
      Toast.show(context.tr('Invalid phone number', 'Numéro invalide'), ToastType.warn);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _step = _Step.confirm);
    _startCountdown();
  }

  Future<void> _confirm() async {
    _countdown?.cancel();
    setState(() => _step = _Step.verifying);
    final state = context.read<AppState>();
    final txn = await state.pay(widget.result, _method, _phone.text.trim());
    if (!mounted) return;
    setState(() {
      _txnId = txn;
      _step = _Step.success;
    });
    Confetti.fire();
  }

  void _finish() {
    context.read<AppState>().recordPurchase(widget.result, _method, _txnId!);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PopScope(
      canPop: !_busy,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22, 14, 22, 30 + MediaQuery.paddingOf(context).bottom),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _busy ? null : () => Navigator.of(context).pop(),
                      child: Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: c.borderStrong,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: switch (_step) {
                        _Step.details => _details(c),
                        _Step.confirm => _confirmStep(c),
                        _Step.verifying => _verifying(c),
                        _Step.success => _success(c),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(AppColors c, String text, {TextAlign align = TextAlign.start}) => Text(
    text,
    textAlign: align,
    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.2, color: c.text),
  );

  Widget _sub(AppColors c, Widget child) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 22),
    child: DefaultTextStyle.merge(
      style: TextStyle(fontSize: 13.5, height: 1.5, color: c.text2),
      child: child,
    ),
  );

  Widget _details(AppColors c) {
    final r = widget.result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(c, context.tr('Unlock your slip', 'Débloquez votre relevé')),
        _sub(c, Text('${r.name} · ${r.stream} · ${r.year}')),
        _PriceBox(label: context.tr('One-time payment', 'Paiement unique'), amount: '1,000', suffix: 'FCFA'),
        Text(
          context.tr('Choose method', 'Choisir le mode'),
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.text2),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final m in PaymentMethod.values) ...[
              Expanded(
                child: _MethodCard(method: m, selected: m == _method, onTap: () => setState(() => _method = m)),
              ),
              if (m != PaymentMethod.values.last) const SizedBox(width: 12),
            ],
          ],
        ),
        const SizedBox(height: 20),
        AppTextField(
          controller: _phone,
          label: context.tr('Mobile money phone number', 'Numéro Mobile Money'),
          icon: FontAwesomeIcons.phone,
          hint: '6XX XXX XXX',
          numeric: true,
          onSubmitted: (_) => _continue(),
          below: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _detected == null
                ? const SizedBox(key: ValueKey('none'), width: double.infinity)
                : Padding(
                    key: ValueKey(_detected),
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.circleCheck, size: 12, color: c.success),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${context.tr('Detected', 'Détecté')}: ${_detected!.label}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.success),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PayLogo(_detected!, height: 16),
                      ],
                    ),
                  ),
          ),
        ),
        AppButton(
          label: context.tr('Continue to payment', 'Continuer'),
          icon: FontAwesomeIcons.lock,
          variant: ButtonVariant.accent,
          onPressed: _continue,
        ),
      ],
    );
  }

  Widget _confirmStep(AppColors c) {
    final ussd = _method.ussd;
    TextSpan strong(String t) => TextSpan(
      text: t,
      style: TextStyle(fontWeight: FontWeight.w700, color: c.primary),
    );
    final steps = [
      [TextSpan(text: '${context.tr('Dial', 'Composez')} '), strong(ussd)],
      [
        TextSpan(text: '${context.tr('Choose', 'Choisissez')} '),
        strong(context.tr('Pay Bill', 'Payer facture')),
        TextSpan(text: ' ${context.tr('then', 'puis')} '),
        strong('SlipNow'),
      ],
      [TextSpan(text: '${context.tr('Enter', 'Entrez')} '), strong(AppConstants.slipPriceLabel)],
      [TextSpan(text: context.tr('Enter your PIN', 'Entrez votre code PIN'))],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(c, context.tr('Confirm payment', 'Confirmer le paiement')),
        _sub(
          c,
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${context.tr('Dial from', 'Composez depuis')} '),
                TextSpan(
                  text: _phone.text.trim(),
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                ),
              ],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: c.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: c.borderStrong, width: 1.5),
          ),
          child: Column(
            children: [
              Text(
                context.tr('DIAL ON YOUR PHONE', 'COMPOSEZ'),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: c.text2),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  boxShadow: c.shadowMd,
                ),
                child: SelectableText(ussd, style: AppTheme.mono(color: c.primary)),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PayLogo(_method, height: 26),
                  const SizedBox(width: 8),
                  Text(
                    _method.label,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.text2),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppButton(
                label: context.tr('Dial now', 'Composer maintenant'),
                icon: FontAwesomeIcons.phone,
                variant: ButtonVariant.ghost,
                compact: true,
                expand: false,
                onPressed: () => ExternalActions.dial(ussd),
              ),
            ],
          ),
        ),
        _Countdown(secondsLeft: _secondsLeft, total: _confirmWindow),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${i + 1}.  '),
                  ...steps[i],
                ],
              ),
              style: TextStyle(fontSize: 13.5, height: 1.8, color: c.text),
            ),
          ),
        const SizedBox(height: 16),
        AppButton(
          label: context.tr('I have confirmed', "J'ai confirmé"),
          icon: FontAwesomeIcons.circleCheck,
          onPressed: _confirm,
        ),
        const SizedBox(height: 10),
        AppButton(
          label: context.tr('Change method', 'Changer de méthode'),
          icon: FontAwesomeIcons.arrowLeft,
          variant: ButtonVariant.ghost,
          onPressed: () {
            _countdown?.cancel();
            setState(() => _step = _Step.details);
          },
        ),
      ],
    );
  }

  Widget _verifying(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(c, context.tr('Verifying payment...', 'Vérification...')),
        _sub(c, Text(context.tr('Please do not close this screen.', 'Ne fermez pas cet écran.'))),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _PulsingLogo(method: _method),
          ),
        ),
        Text(
          '${context.tr('Waiting for', 'En attente de')} ${_method.label}…',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text2),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _success(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Padding(padding: EdgeInsets.only(bottom: 16), child: _AnimatedCheck()),
        ),
        _title(c, context.tr('Payment successful', 'Paiement réussi'), align: TextAlign.center),
        _sub(
          c,
          Text(
            context.tr('Your official slip is now unlocked.', 'Votre relevé officiel est débloqué.'),
            textAlign: TextAlign.center,
          ),
        ),
        _PriceBox(label: 'Transaction ID', amount: _txnId ?? '', success: true),
        AppButton(
          label: context.tr('View my official slip', 'Voir mon relevé'),
          icon: FontAwesomeIcons.filePdf,
          onPressed: _finish,
        ),
      ],
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.secondsLeft, required this.total});

  final int secondsLeft;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final expired = secondsLeft == 0;
    final mm = (secondsLeft ~/ 60).toString();
    final ss = (secondsLeft % 60).toString().padLeft(2, '0');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: expired ? c.warnSoft : c.surface2,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: secondsLeft / total,
                  strokeWidth: 3,
                  color: expired ? c.warn : c.primary,
                  backgroundColor: c.border,
                ),
                FaIcon(FontAwesomeIcons.hourglassHalf, size: 10, color: expired ? c.warn : c.primary),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              expired
                  ? context.tr(
                      'Taking longer than usual? Dial again, then tap "I have confirmed".',
                      'Cela prend du temps ? Recomposez puis touchez « J\'ai confirmé ».',
                    )
                  : context.tr('Approve the prompt on your phone', 'Validez la demande sur votre téléphone'),
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: expired ? c.warn : c.text2,
              ),
            ),
          ),
          if (!expired) ...[
            const SizedBox(width: 8),
            Text('$mm:$ss', style: AppTheme.mono(size: 15, color: c.primary)),
          ],
        ],
      ),
    );
  }
}

class _PulsingLogo extends StatefulWidget {
  const _PulsingLogo({required this.method});

  final PaymentMethod method;

  @override
  State<_PulsingLogo> createState() => _PulsingLogoState();
}

class _PulsingLogoState extends State<_PulsingLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 130,
      height: 130,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Stack(
          alignment: Alignment.center,
          children: [
            for (final offset in [0.0, 0.5])
              Builder(
                builder: (_) {
                  final t = (_c.value + offset) % 1;
                  return Container(
                    width: 70 + 60 * t,
                    height: 70 + 60 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.primary.withValues(alpha: 0.35 * (1 - t)), width: 2),
                    ),
                  );
                },
              ),
            child!,
          ],
        ),
        child: Container(
          width: 76,
          height: 76,
          padding: const EdgeInsets.all(14),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: colors.surface, shape: BoxShape.circle, boxShadow: colors.shadowMd),
          child: PayLogo(widget.method, height: 40),
        ),
      ),
    );
  }
}

/// Circle pops in, a tick draws itself and a ring ripples outwards.
class _AnimatedCheck extends StatefulWidget {
  const _AnimatedCheck();

  @override
  State<_AnimatedCheck> createState() => _AnimatedCheckState();
}

class _AnimatedCheckState extends State<_AnimatedCheck> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 120,
      height: 120,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final pop = Curves.easeOutBack.transform((_c.value / 0.45).clamp(0.0, 1.0));
          final draw = Curves.easeOutCubic.transform(((_c.value - 0.35) / 0.45).clamp(0.0, 1.0));
          final ripple = Curves.easeOut.transform(((_c.value - 0.3) / 0.7).clamp(0.0, 1.0));
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 84 + 36 * ripple,
                height: 84 + 36 * ripple,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.success.withValues(alpha: 0.4 * (1 - ripple)), width: 3),
                ),
              ),
              Transform.scale(
                scale: pop,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: colors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.success.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: CustomPaint(painter: _CheckPainter(progress: draw)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.67)
      ..lineTo(size.width * 0.73, size.height * 0.37);
    final metric = path.computeMetrics().first;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(5, size.width * 0.075)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}

class _PriceBox extends StatelessWidget {
  const _PriceBox({required this.label, required this.amount, this.suffix, this.success = false});

  final String label;
  final String amount;
  final String? suffix;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final labelColor = success ? c.success : c.onAccentSoft;
    final amountColor = success ? c.success : (c.isDark ? const Color(0xFFFFE7B5) : AppColors.onAccent);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: success ? c.successSoft : c.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: labelColor),
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: amount),
                if (suffix != null)
                  TextSpan(
                    text: ' $suffix',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
              ],
            ),
            style: TextStyle(
              fontSize: success ? 14 : 24,
              fontWeight: FontWeight.w800,
              letterSpacing: success ? 0 : -0.5,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({required this.method, required this.selected, required this.onTap});

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      label: '${context.tr('Pay with', 'Payer avec')} ${method.label}',
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 100),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          decoration: BoxDecoration(
            color: selected ? c.primarySoft : c.surface,
            border: Border.all(color: selected ? c.primary : c.border, width: 1.5),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(constraints: const BoxConstraints(maxWidth: 96), child: PayLogo(method)),
                    const SizedBox(height: 10),
                    Text(
                      method.label,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.text),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -8,
                right: -2,
                child: AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  curve: selected ? Curves.easeOutBack : Curves.easeIn,
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                    child: const FaIcon(FontAwesomeIcons.check, size: 10, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
