import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Label + bordered input shell with a left accent bar when focused.
class FieldShell extends StatefulWidget {
  const FieldShell({
    super.key,
    this.label,
    this.optionalHint,
    required this.icon,
    required this.builder,
    this.trailing,
    this.focusNode,
    this.below,
  });

  final String? label;
  final String? optionalHint;
  final FaIconData icon;
  final Widget Function(FocusNode focusNode) builder;
  final Widget? trailing;
  final FocusNode? focusNode;
  final Widget? below;

  @override
  State<FieldShell> createState() => _FieldShellState();
}

class _FieldShellState extends State<FieldShell> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() => setState(() => _focused = _focus.hasFocus);

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text.rich(
                TextSpan(
                  text: widget.label,
                  children: [
                    if (widget.optionalHint != null)
                      TextSpan(
                        text: ' ${widget.optionalHint}',
                        style: TextStyle(color: c.text3, fontWeight: FontWeight.w400),
                      ),
                  ],
                ),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text2),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 56),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: _focused ? c.primary : c.border, width: 1.5),
              boxShadow: _focused ? [BoxShadow(color: c.primarySoft, spreadRadius: 4)] : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md - 1.5),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      width: _focused ? 3 : 0,
                      decoration: BoxDecoration(
                        color: c.primary,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Center(child: FaIcon(widget.icon, size: 15, color: c.text3)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: widget.builder(_focus)),
                        ?widget.trailing,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ?widget.below,
        ],
      ),
    );
  }
}

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.icon,
    this.label,
    this.optionalHint,
    this.hint,
    this.keyboardType,
    this.password = false,
    this.showStrength = false,
    this.numeric = false,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.below,
    this.trailing,
  });

  final FocusNode? focusNode;
  final Widget? below;
  final Widget? trailing;
  final TextEditingController controller;
  final FaIconData icon;
  final String? label;
  final String? optionalHint;
  final String? hint;
  final TextInputType? keyboardType;
  final bool password;
  final bool showStrength;
  final bool numeric;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FieldShell(
      label: widget.label,
      optionalHint: widget.optionalHint,
      icon: widget.icon,
      focusNode: widget.focusNode,
      trailing: widget.password
          ? IconButton(
              onPressed: () => setState(() => _obscured = !_obscured),
              tooltip: _obscured
                  ? context.tr('Show password', 'Afficher le mot de passe')
                  : context.tr('Hide password', 'Masquer le mot de passe'),
              icon: FaIcon(_obscured ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash, size: 15, color: c.text3),
            )
          : widget.trailing,
      below: widget.showStrength
          ? ValueListenableBuilder(
              valueListenable: widget.controller,
              builder: (_, value, _) => PasswordMeter(password: value.text),
            )
          : widget.below,
      builder: (focus) => TextField(
        controller: widget.controller,
        focusNode: focus,
        obscureText: widget.password && _obscured,
        keyboardType: widget.numeric ? TextInputType.number : widget.keyboardType,
        inputFormatters: widget.numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        autofillHints: widget.autofillHints,
        textCapitalization: widget.textCapitalization,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.text),
        decoration: InputDecoration(
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          border: InputBorder.none,
          hintText: widget.hint,
          hintStyle: TextStyle(color: c.text3, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}

class AppSelectField<T> extends StatelessWidget {
  const AppSelectField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final FaIconData icon;
  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FieldShell(
      label: label,
      icon: icon,
      builder: (focus) => DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          focusNode: focus,
          value: value,
          isExpanded: true,
          dropdownColor: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          icon: FaIcon(FontAwesomeIcons.chevronDown, size: 12, color: c.text3),
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.text),
          items: [for (final (v, text) in items) DropdownMenuItem(value: v, child: Text(text))],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class PasswordMeter extends StatelessWidget {
  const PasswordMeter({super.key, required this.password});

  final String password;

  static int strengthOf(String v) {
    var s = 0;
    if (v.length >= 6) s = 1;
    if (v.length >= 8) s = 2;
    if (v.length >= 8 && RegExp(r'[0-9]').hasMatch(v) && RegExp(r'[^A-Za-z0-9]').hasMatch(v)) {
      s = 3;
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = strengthOf(password);
    final (color, label) = switch (s) {
      <= 1 => (c.danger, context.tr('Weak', 'Faible')),
      2 => (c.warn, context.tr('Fair', 'Moyen')),
      _ => (c.success, context.tr('Strong', 'Fort')),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                decoration: BoxDecoration(color: i < s ? color : c.border, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            if (i < 2) const SizedBox(width: 4),
          ],
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(
              label.toUpperCase(),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
