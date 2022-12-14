// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forum.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ForumDataAdapter extends TypeAdapter<ForumData> {
  @override
  final int typeId = 1;

  @override
  ForumData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ForumData(
      id: fields[0] as int,
      name: fields[1] as String,
      displayName: fields[2] == null ? '' : fields[2] as String,
      message: fields[3] == null ? '' : fields[3] as String,
      maxPage: fields[4] == null ? 100 : fields[4] as int,
      isTimeline: fields[5] == null ? false : fields[5] as bool,
      forumGroupId: fields[6] as int?,
      isDeprecated: fields[7] == null ? false : fields[7] as bool,
      userDefinedName: fields[8] as String?,
      isHidden: fields[9] == null ? false : fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ForumData obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.displayName)
      ..writeByte(3)
      ..write(obj.message)
      ..writeByte(4)
      ..write(obj.maxPage)
      ..writeByte(5)
      ..write(obj.isTimeline)
      ..writeByte(6)
      ..write(obj.forumGroupId)
      ..writeByte(7)
      ..write(obj.isDeprecated)
      ..writeByte(8)
      ..write(obj.userDefinedName)
      ..writeByte(9)
      ..write(obj.isHidden);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForumDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BlockForumDataAdapter extends TypeAdapter<BlockForumData> {
  @override
  final int typeId = 5;

  @override
  BlockForumData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BlockForumData(
      forumId: fields[0] as int,
      timelineId: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BlockForumData obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.forumId)
      ..writeByte(1)
      ..write(obj.timelineId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockForumDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
