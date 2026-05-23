// hud/hud_toggle_button.dart
import 'package:flutter/material.dart';

class HudToggleButton extends StatefulWidget {
  final ValueNotifier<bool> hudVisible;

  const HudToggleButton({super.key, required this.hudVisible});

  @override
  State<HudToggleButton> createState() => _HudToggleButtonState();
}

class _HudToggleButtonState extends State<HudToggleButton> {
  @override
  void initState() {
    super.initState();
    widget.hudVisible.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.hudVisible.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final visible = widget.hudVisible.value;

    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, right: 12),
          child: GestureDetector(
            onTap: () => widget.hudVisible.value = !widget.hudVisible.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: visible ? 36 : 28,
              height: visible ? 36 : 28,
              decoration: BoxDecoration(
                color: visible
                    ? Colors.white.withOpacity(0.85)
                    : Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                visible ? Icons.visibility : Icons.visibility_off,
                size: visible ? 20 : 14,
                color: visible ? Colors.black87 : Colors.white54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
