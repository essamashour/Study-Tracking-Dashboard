
part of 'course_model.dart';


class CourseModelAdapter extends TypeAdapter<CourseModel> {
  @override
  final int typeId = 0;

  @override
  CourseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CourseModel(
      id: fields[0] as String,
      name: fields[1] as String,
      lectures: fields[2] as int,
      labs: fields[3] as int,
      sections: fields[4] as int,
      schedule: (fields[5] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, CourseModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.lectures)
      ..writeByte(3)
      ..write(obj.labs)
      ..writeByte(4)
      ..write(obj.sections)
      ..writeByte(5)
      ..write(obj.schedule);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
