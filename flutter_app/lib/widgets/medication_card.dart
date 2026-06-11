import 'package:flutter/material.dart';
import '../models/prescription.dart';
import '../theme.dart';

class MedicationCard extends StatefulWidget {
  final Medication medication;
  final int index;
  final void Function(String language) onListen;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.index,
    required this.onListen,
  });

  @override
  State<MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<MedicationCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  Color get _accentColor =>
      AppColors.cardAccents[widget.index % AppColors.cardAccents.length];
  Color get _lightColor =>
      AppColors.cardAccentLights[widget.index % AppColors.cardAccentLights.length];

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEF1)),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card header — always visible
          _CardHeader(
            medication: widget.medication,
            index: widget.index,
            accentColor: _accentColor,
            lightColor: _lightColor,
            expanded: _expanded,
            onTap: _toggleExpand,
          ),

          // Expandable details
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: _CardDetails(
              medication: widget.medication,
              accentColor: _accentColor,
              onListen: widget.onListen,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card Header ──────────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  final Medication medication;
  final int index;
  final Color accentColor;
  final Color lightColor;
  final bool expanded;
  final VoidCallback onTap;

  const _CardHeader({
    required this.medication,
    required this.index,
    required this.accentColor,
    required this.lightColor,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: expanded
          ? const BorderRadius.vertical(top: Radius.circular(20))
          : BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            // Medicine icon / index
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: lightColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('💊', style: TextStyle(fontSize: 20)),
                    Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication.name,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _PillChip(
                          label: medication.dosage, color: accentColor),
                      const SizedBox(width: 6),
                      _PillChip(
                          label: medication.frequency, color: accentColor),
                    ],
                  ),
                ],
              ),
            ),

            AnimatedRotation(
              duration: const Duration(milliseconds: 300),
              turns: expanded ? 0.5 : 0,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: accentColor,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card Details ─────────────────────────────────────────────────────────────

class _CardDetails extends StatelessWidget {
  final Medication medication;
  final Color accentColor;
  final void Function(String) onListen;

  const _CardDetails({
    required this.medication,
    required this.accentColor,
    required this.onListen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: const Color(0xFFEEF2F5))),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detail rows
          _DetailRow(icon: '⏱️', label: 'Duration', value: medication.duration),
          _DetailRow(icon: '🎯', label: 'Purpose', value: medication.purpose),
          _DetailRow(
              icon: '📌',
              label: 'Instructions',
              value: medication.instructions),

          const SizedBox(height: 14),

          // Listen buttons for this card
          Row(
            children: [
              Expanded(
                child: _MiniListenBtn(
                  label: 'हिंदी',
                  icon: '🇮🇳',
                  color: accentColor,
                  onTap: () => onListen('hi-IN'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniListenBtn(
                  label: 'English',
                  icon: '🔊',
                  color: accentColor,
                  onTap: () => onListen('en-IN'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final Color color;

  const _PillChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}

class _MiniListenBtn extends StatelessWidget {
  final String label;
  final String icon;
  final Color color;
  final VoidCallback onTap;

  const _MiniListenBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
