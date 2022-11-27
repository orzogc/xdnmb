// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controller.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PostBaseDataAdapter extends TypeAdapter<PostBaseData> {
  @override
  final int typeId = 7;

  @override
  PostBaseData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PostBaseData(
      id: fields[0] as int,
      forumId: fields[1] as int?,
      replyCount: fields[2] as int?,
      postTime: fields[3] as DateTime,
      userHash: fields[4] as String,
      name: fields[5] as String,
      title: fields[6] as String,
      content: fields[7] as String,
      isSage: fields[8] as bool?,
      isAdmin: fields[9] as bool,
      isHidden: fields[10] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, PostBaseData obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.forumId)
      ..writeByte(2)
      ..write(obj.replyCount)
      ..writeByte(3)
      ..write(obj.postTime)
      ..writeByte(4)
      ..write(obj.userHash)
      ..writeByte(5)
      ..write(obj.name)
      ..writeByte(6)
      ..write(obj.title)
      ..writeByte(7)
      ..write(obj.content)
      ..writeByte(8)
      ..write(obj.isSage)
      ..writeByte(9)
      ..write(obj.isAdmin)
      ..writeByte(10)
      ..write(obj.isHidden);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostBaseDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PostListControllerDataAdapter
    extends TypeAdapter<PostListControllerData> {
  @override
  final int typeId = 9;

  @override
  PostListControllerData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PostListControllerData(
      postListType: fields[0] as PostListType,
      id: fields[1] as int?,
      page: fields[2] as int,
      post: fields[3] as PostBaseData?,
      pageIndex: fields[4] as int?,
      dateRange: (fields[5] as List?)?.cast<DateTimeRange?>(),
    );
  }

  @override
  void write(BinaryWriter writer, PostListControllerData obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.postListType)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.page)
      ..writeByte(3)
      ..write(obj.post)
      ..writeByte(4)
      ..write(obj.pageIndex)
      ..writeByte(5)
      ..write(obj.dateRange);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostListControllerDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PostListTypeAdapter extends TypeAdapter<PostListType> {
  @override
  final int typeId = 8;

  @override
  PostListType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PostListType.thread;
      case 1:
        return PostListType.onlyPoThread;
      case 2:
        return PostListType.forum;
      case 3:
        return PostListType.timeline;
      case 4:
        return PostListType.feed;
      case 5:
        return PostListType.history;
      default:
        return PostListType.thread;
    }
  }

  @override
  void write(BinaryWriter writer, PostListType obj) {
    switch (obj) {
      case PostListType.thread:
        writer.writeByte(0);
        break;
      case PostListType.onlyPoThread:
        writer.writeByte(1);
        break;
      case PostListType.forum:
        writer.writeByte(2);
        break;
      case PostListType.timeline:
        writer.writeByte(3);
        break;
      case PostListType.feed:
        writer.writeByte(4);
        break;
      case PostListType.history:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostListTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
