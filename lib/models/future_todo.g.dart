// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'future_todo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FutureTodoAdapter extends TypeAdapter<FutureTodo> {
  @override
  final int typeId = 2;

  @override
  FutureTodo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FutureTodo(
      indents: fields[2] as int,
      text: fields[0] as String,
      finished: fields[1] as bool,
      index: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, FutureTodo obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.finished)
      ..writeByte(2)
      ..write(obj.indents)
      ..writeByte(3)
      ..write(obj.index);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FutureTodoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
