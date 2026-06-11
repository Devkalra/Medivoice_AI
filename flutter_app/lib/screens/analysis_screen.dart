import 'dart:io';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../models/prescription.dart';
import 'results_screen.dart';

class AnalysisScreen extends StatefulWidget {
  final File imageFile;

  const AnalysisScreen({super.key, required this.imageFile});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with TickerProviderStateMixin {
  late AnimationController _dotController;
  late AnimationController _pulseController;
  late AnimationController _progressController;

  int _currentStep = 0;
  bool _hasError = false;
  String _errorMessage = '';

  static const List<_ProcessStep> _steps = [
    _ProcessStep('🔍', 'Reading prescription...', 'Extracting text using Sarvam Vision OCR'),
    _ProcessStep('🧠', 'Analyzing medications...', 'Processing with Sarvam 105B AI'),
    _ProcessStep('💊', 'Identifying medicines...', 'Expanding abbreviations and dosages'),
    _ProcessStep('✍️', 'Preparing summary...', 'Creating patient-friendly explanations'),
    _ProcessStep('✅', 'Almost done!', 'Finalizing your prescription report'),
  ];

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    // Simulate step progression while waiting for API
    final stepDuration = const Duration(milliseconds: 1800);

    for (int i = 0; i < _steps.length - 1; i++) {
      await Future.delayed(stepDuration);
      if (!mounted) return;
      setState(() => _currentStep = i + 1);
    }

    // Now actually call the API
    try {
      final result = await ApiService().analyzePrescription(widget.imageFile);
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ResultsScreen(result: result),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _dotController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.splash),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _hasError ? _buildError() : _buildLoading(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pulsing icon
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) {
            final scale = 0.92 + (_pulseController.value * 0.16);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    _steps[_currentStep].icon,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 40),

        // Step title
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            _steps[_currentStep].title,
            key: ValueKey(_currentStep),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            _steps[_currentStep].subtitle,
            key: ValueKey('sub_$_currentStep'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ),

        const SizedBox(height: 48),

        // Progress dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_steps.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == _currentStep ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i <= _currentStep
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),

        const SizedBox(height: 64),

        // Step list
        ..._steps.asMap().entries.map((e) => _StepItem(
              step: e.value,
              state: e.key < _currentStep
                  ? _StepState.done
                  : e.key == _currentStep
                      ? _StepState.active
                      : _StepState.pending,
              controller: _dotController,
            )),

        const SizedBox(height: 32),

        Text(
          'This may take up to 30 seconds\nPlease keep the app open',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: Colors.white.withOpacity(0.5),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('❌', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 24),
        const Text(
          'Analysis failed',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 36),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Go Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _currentStep = 0;
                    _errorMessage = '';
                  });
                  _startAnalysis();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _StepState { done, active, pending }

class _StepItem extends StatelessWidget {
  final _ProcessStep step;
  final _StepState state;
  final AnimationController controller;

  const _StepItem({
    required this.step,
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: state == _StepState.done
                ? const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18)
                : state == _StepState.active
                    ? AnimatedBuilder(
                        animation: controller,
                        builder: (_, __) => Opacity(
                          opacity: 0.5 + (controller.value * 0.5),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                      ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step.title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: state == _StepState.active
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: state == _StepState.pending
                    ? Colors.white.withOpacity(0.35)
                    : Colors.white.withOpacity(0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessStep {
  final String icon;
  final String title;
  final String subtitle;
  const _ProcessStep(this.icon, this.title, this.subtitle);
}
