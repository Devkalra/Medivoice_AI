import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/prescription.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../widgets/medication_card.dart';
import 'home_screen.dart';

class ResultsScreen extends StatefulWidget {
  final PrescriptionResult result;

  const ResultsScreen({super.key, required this.result});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _enterController;
  final AudioService _audioService = AudioService();

  bool _isPlayingHindi = false;
  bool _isPlayingEnglish = false;
  bool _ttsLoading = false;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    _audioService.stop();
    super.dispose();
  }

  Future<void> _playTTS(String language) async {
    if (_ttsLoading) return;
    setState(() {
      _ttsLoading = true;
      _isPlayingHindi = language == 'hi-IN';
      _isPlayingEnglish = language != 'hi-IN';
    });
    try {
      final audioBase64 =
          await ApiService().prescriptionToSpeech(widget.result, language);
      if (audioBase64.isNotEmpty) {
        await _audioService.playBase64Audio(audioBase64);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Audio playback failed: $e'),
          backgroundColor: Colors.red.shade700,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _ttsLoading = false;
          _isPlayingHindi = false;
          _isPlayingEnglish = false;
        });
      }
    }
  }

  Future<void> _playMedicationTTS(Medication med, String language) async {
    final text = language == 'hi-IN'
        ? '${med.name}। खुराक ${med.dosage}। ${med.frequency} लें। ${med.duration} के लिए। ${med.purpose}। ${med.instructions}।'
        : '${med.name}. Take ${med.dosage}, ${med.frequency}, for ${med.duration}. ${med.purpose}. ${med.instructions}.';
    try {
      final audioBase64 = await ApiService().textToSpeech(text, language);
      if (audioBase64.isNotEmpty) {
        await _audioService.playBase64Audio(audioBase64);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Audio error: $e'),
          backgroundColor: Colors.red.shade700,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            pinned: true,
            backgroundColor: AppColors.bgPrimary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.home_rounded),
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (_) => false,
              ),
            ),
            title: const Text('Prescription Summary',
                style: AppTextStyles.headlineLarge),
          ),

          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _enterController,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SuccessBanner(
                      summary: widget.result.patientSummary,
                      medicationCount: widget.result.medications.length,
                    ),
                    const SizedBox(height: 20),
                    _ListenButtons(
                      isPlayingHindi: _isPlayingHindi,
                      isPlayingEnglish: _isPlayingEnglish,
                      isLoading: _ttsLoading,
                      onHindi: () => _playTTS('hi-IN'),
                      onEnglish: () => _playTTS('en-IN'),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text('Medications',
                            style: AppTextStyles.displayMedium),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${widget.result.medications.length}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text('Tap any card to expand, then listen',
                        style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final med = widget.result.medications[index];
                  return FutureBuilder(
                    future: Future.delayed(
                        Duration(milliseconds: 100 + (index * 80))),
                    builder: (context, snapshot) => AnimatedOpacity(
                      opacity: snapshot.connectionState ==
                              ConnectionState.done
                          ? 1.0
                          : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: MedicationCard(
                          medication: med,
                          index: index,
                          onListen: (lang) => _playMedicationTTS(med, lang),
                        ),
                      ),
                    ),
                  );
                },
                childCount: widget.result.medications.length,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, MediaQuery.of(context).padding.bottom + 24),
              child: Column(
                children: [
                  if (widget.result.disclaimer != null)
                    _DisclaimerCard(text: widget.result.disclaimer!),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (_) => false,
                    ),
                    icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: const Text('Scan Another Prescription'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SuccessBanner extends StatelessWidget {
  final String summary;
  final int medicationCount;

  const _SuccessBanner(
      {required this.summary, required this.medicationCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0F4F7), Color(0xFFCCEEF4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Analysis Complete',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '$medicationCount medicine${medicationCount != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.primaryDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListenButtons extends StatelessWidget {
  final bool isPlayingHindi;
  final bool isPlayingEnglish;
  final bool isLoading;
  final VoidCallback onHindi;
  final VoidCallback onEnglish;

  const _ListenButtons({
    required this.isPlayingHindi,
    required this.isPlayingEnglish,
    required this.isLoading,
    required this.onHindi,
    required this.onEnglish,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Listen to full summary',
            style: AppTextStyles.headlineMedium),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ListenBtn(
                label: 'हिंदी में सुनें',
                flag: '🇮🇳',
                isActive: isPlayingHindi,
                isLoading: isLoading && isPlayingHindi,
                color: AppColors.primary,
                onTap: onHindi,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ListenBtn(
                label: 'Listen in English',
                flag: '🔊',
                isActive: isPlayingEnglish,
                isLoading: isLoading && isPlayingEnglish,
                color: AppColors.accent,
                onTap: onEnglish,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ListenBtn extends StatelessWidget {
  final String label;
  final String flag;
  final bool isActive;
  final bool isLoading;
  final Color color;
  final VoidCallback onTap;

  const _ListenBtn({
    required this.label,
    required this.flag,
    required this.isActive,
    required this.isLoading,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? color : color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isActive ? Colors.white : color,
                  ),
                )
              else
                Text(flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : color,
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

class _DisclaimerCard extends StatelessWidget {
  final String text;

  const _DisclaimerCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.warning.withOpacity(0.85),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
