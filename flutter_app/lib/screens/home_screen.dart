import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import 'image_preview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late AnimationController _cardController;
  late Animation<double> _cardOpacity;
  late Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cardOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeIn),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic));
    _cardController.forward();
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? xFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (xFile != null && mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ImagePreviewScreen(imageFile: File(xFile.path)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}. '
                'Please check permissions.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppGradients.primaryHeader,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text('🩺', style: TextStyle(fontSize: 22)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MediVoice AI',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              // Text(
                              //   'by Sarvam AI',
                              //   style: TextStyle(
                              //     fontFamily: 'Inter',
                              //     fontSize: 12,
                              //     color: Colors.white60,
                              //   ),
                              // ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Understand your\nprescription easily',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Upload or capture your doctor\'s prescription and\nget a clear explanation in Hindi or English.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.78),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _cardOpacity,
              child: SlideTransition(
                position: _cardSlide,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Choose an option',
                        style: AppTextStyles.headlineLarge,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Take a clear photo or upload from your gallery',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 24),

                      // Upload button
                      _ActionCard(
                        icon: '📁',
                        title: 'Upload Prescription',
                        subtitle: 'Choose from your photo gallery',
                        accentColor: AppColors.primary,
                        lightColor: AppColors.bgMuted,
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                      const SizedBox(height: 16),

                      // Capture button
                      _ActionCard(
                        icon: '📷',
                        title: 'Capture Image',
                        subtitle: 'Take a photo with your camera',
                        accentColor: AppColors.accent,
                        lightColor: const Color(0xFFFFF5E5),
                        onTap: () => _pickImage(ImageSource.camera),
                      ),

                      const SizedBox(height: 32),

                      // Tips card
                      _TipsCard(),

                      const SizedBox(height: 32),

                      // Disclaimer
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.warning.withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('⚠️', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'MediVoice AI helps you understand prescriptions. '
                                'It does not provide medical advice. '
                                'Always consult your doctor.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: AppColors.warning.withOpacity(0.9),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color lightColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.lightColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EEF1)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: lightColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: accentColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final List<_Tip> tips = const [
    _Tip('💡', 'Good lighting', 'Place the prescription in bright light'),
    _Tip('🔍', 'Hold steady', 'Keep the camera still to avoid blur'),
    _Tip('📄', 'Full view', 'Capture the entire prescription in frame'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tips for best results',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 14),
          ...tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text(t.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(t.subtitle,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            )),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _Tip {
  final String icon;
  final String title;
  final String subtitle;
  const _Tip(this.icon, this.title, this.subtitle);
}
