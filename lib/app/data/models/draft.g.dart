// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PostDraftDataAdapter extends TypeAdapter<PostDraftData> {
  @override
  final int typeId = 3;

  @override
  PostDraftData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PostDraftData(
      title: fields[0] as String?,
      name: fields[1] as String?,
      content: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PostDraftData obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.content);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostDraftDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
