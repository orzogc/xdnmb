// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emoticon.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmoticonDataAdapter extends TypeAdapter<EmoticonData> {
  @override
  final int typeId = 4;

  @override
  EmoticonData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmoticonData(
      name: fields[0] as String,
      text: fields[1] as String,
      offset: fields[2] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, EmoticonData obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.offset);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmoticonDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
