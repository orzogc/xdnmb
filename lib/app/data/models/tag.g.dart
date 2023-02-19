// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TagDataAdapter extends TypeAdapter<TagData> {
  @override
  final int typeId = 11;

  @override
  TagData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TagData(
      id: fields[0] as int,
      name: fields[1] as String,
      backgroundColorValue: fields[2] as int?,
      textColorValue: fields[3] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, TagData obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.backgroundColorValue)
      ..writeByte(3)
      ..write(obj.textColorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
