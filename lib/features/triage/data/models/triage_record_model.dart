import 'package:hive/hive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/triage_record.dart';

part 'triage_record_model.g.dart';

/// Hive-persisted representation of a triage record.
///
/// This mirrors [TriageRecord] field-for-field but is intentionally a
/// separate class: it carries Hive annotations and a manually written
/// [TypeAdapter] (see the generated-by-hand `.g.dart` file), so persistence
/// concerns never leak into the domain entity. [toEntity]/[fromEntity]
/// translate between the two.
///
/// Extending [HiveObject] gives us `.save()` for in-place updates (used by
/// [TriageLocalDataSourceImpl.markSynced]).
@HiveType(typeId: 0)
class TriageRecordModel extends HiveObject {
  TriageRecordModel({
    required this.id,
    required this.patientName,
    required this.conditionDescription,
    required this.priority,
    required this.statusIndex,
    required this.createdAt,
    required this.isSynced,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String patientName;

  @HiveField(2)
  String conditionDescription;

  @HiveField(3)
  int priority;

  /// Stored as the index into [TriageStatus.values] since Hive's built-in
  /// generator handles primitives most reliably; [status] exposes the
  /// typed enum for callers.
  @HiveField(4)
  int statusIndex;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  bool isSynced;

  TriageStatus get status => TriageStatus.values[statusIndex];

  factory TriageRecordModel.fromEntity(TriageRecord entity) {
    return TriageRecordModel(
      id: entity.id,
      patientName: entity.patientName,
      conditionDescription: entity.conditionDescription,
      priority: entity.priority,
      statusIndex: entity.status.index,
      createdAt: entity.createdAt,
      isSynced: entity.isSynced,
    );
  }

  TriageRecord toEntity() {
    return TriageRecord(
      id: id,
      patientName: patientName,
      conditionDescription: conditionDescription,
      priority: priority,
      status: status,
      createdAt: createdAt,
      isSynced: isSynced,
    );
  }
}
