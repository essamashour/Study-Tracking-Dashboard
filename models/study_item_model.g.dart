
part of 'study_item_model.dart';

class StudyItemModelAdapter extends TypeAdapter<StudyItemModel> {
  @override
  final int typeId = 1;

  @override
  StudyItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudyItemModel(
      id: fields[0] as String,
      courseId: fields[1] as String,
      courseName: fields[2] as String,
      kind: fields[3] as StudyItemKind,
      title: fields[4] as String,
      deadline: fields[5] as DateTime?,
      isDone: fields[6] as bool,
      priority: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, StudyItemModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.courseId)
      ..writeByte(2)
      ..write(obj.courseName)
      ..writeByte(3)
      ..write(obj.kind)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.deadline)
      ..writeByte(6)
      ..write(obj.isDone)
      ..writeByte(7)
      ..write(obj.priority);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
