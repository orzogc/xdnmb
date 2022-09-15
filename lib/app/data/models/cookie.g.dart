// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cookie.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CookieDataAdapter extends TypeAdapter<CookieData> {
  @override
  final int typeId = 2;

  @override
  CookieData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CookieData(
      name: fields[0] as String,
      userHash: fields[1] as String,
      id: fields[2] as int?,
      isDeprecated: fields[3] == null ? false : fields[3] as bool,
      note: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CookieData obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.userHash)
      ..writeByte(2)
      ..write(obj.id)
      ..writeByte(3)
      ..write(obj.isDeprecated)
      ..writeByte(4)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CookieDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
