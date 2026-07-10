import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_constants.dart';

/// Pure domain representation of a single triage record. This is what the
/// UI and use cases work with; it has no knowledge of Hive, JSON, or any
/// other persistence/transport detail. That translation happens in the
/// data layer's [TriageRecordModel].
class TriageRecord extends Equatable {
  const TriageRecord({
    required this.id,
    required this.patientName,
    required this.conditionDescription,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.isSynced,
  });

  final String id;
  final String patientName;
  final String conditionDescription;
  final int priority;
  final TriageStatus status;
  final DateTime createdAt;
  final bool isSynced;

  TriageRecord copyWith({
    String? id,
    String? patientName,
    String? conditionDescription,
    int? priority,
    TriageStatus? status,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return TriageRecord(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      conditionDescription: conditionDescription ?? this.conditionDescription,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props => [
        id,
        patientName,
        conditionDescription,
        priority,
        status,
        createdAt,
        isSynced,
      ];
}
