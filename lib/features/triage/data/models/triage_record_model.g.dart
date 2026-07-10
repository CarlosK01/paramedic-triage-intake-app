// GENERATED CODE - hand-written to match what `hive_generator` would emit.
//
// NOTE: This file is normally produced by running:
//   flutter pub run build_runner build --delete-conflicting-outputs
// It has been hand-written here (mechanically, field-for-field) because
// this environment has no network access to pub.dev / no Flutter SDK
// installed to run codegen. Regenerating it via build_runner in a real
// Flutter environment is safe and will produce an equivalent adapter -
// see README.md "How to run" for the exact command.

part of 'triage_record_model.dart';

class TriageRecordModelAdapter extends TypeAdapter<TriageRecordModel> {
  @override
  final int typeId = 0;

  @override
  TriageRecordModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TriageRecordModel(
      id: fields[0] as String,
      patientName: fields[1] as String,
      conditionDescription: fields[2] as String,
      priority: fields[3] as int,
      statusIndex: fields[4] as int,
      createdAt: fields[5] as DateTime,
      isSynced: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TriageRecordModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientName)
      ..writeByte(2)
      ..write(obj.conditionDescription)
      ..writeByte(3)
      ..write(obj.priority)
      ..writeByte(4)
      ..write(obj.statusIndex)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TriageRecordModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
