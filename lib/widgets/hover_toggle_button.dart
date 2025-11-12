import 'package:flutter/material.dart';

class HoverToggleButton extends StatefulWidget {
  final String labelOn;
  final String labelOff;
  final bool initialValue;
  final Function(bool) onChanged;
  final Color? activeColor;
  final Color? inactiveColor;

  const HoverToggleButton({
    super.key,
    required this.labelOn,
    required this.labelOff,
    required this.initialValue,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  _HoverToggleButtonState createState() => _HoverToggleButtonState();
}

class _HoverToggleButtonState extends State<HoverToggleButton> {
  late bool _isOn;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _isOn = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: _isOn
              ? (widget.activeColor ?? (_isHovered ? Colors.greenAccent : Colors.green))
              : (widget.inactiveColor ?? (_isHovered ? Colors.grey[400] : Colors.grey[600])),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            setState(() => _isOn = !_isOn);
            widget.onChanged(_isOn);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Text(
              _isOn ? widget.labelOn : widget.labelOff,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}