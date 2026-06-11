class Medication {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String purpose;
  final String instructions;

  const Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.purpose,
    required this.instructions,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      name: json['name'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      duration: json['duration'] ?? '',
      purpose: json['purpose'] ?? '',
      instructions: json['instructions'] ?? '',
    );
  }
}

class PrescriptionResult {
  final bool success;
  final String patientSummary;
  final List<Medication> medications;
  final String? disclaimer;
  final String? rawOcrText;

  const PrescriptionResult({
    required this.success,
    required this.patientSummary,
    required this.medications,
    this.disclaimer,
    this.rawOcrText,
  });

  factory PrescriptionResult.fromJson(Map<String, dynamic> json) {
    return PrescriptionResult(
      success: json['success'] ?? false,
      patientSummary: json['patient_summary'] ?? '',
      medications: (json['medications'] as List<dynamic>? ?? [])
          .map((m) => Medication.fromJson(m as Map<String, dynamic>))
          .toList(),
      disclaimer: json['disclaimer'],
      rawOcrText: json['raw_ocr_text'],
    );
  }
}
