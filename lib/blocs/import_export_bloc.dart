import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:todo/utils/hive_repository.dart';

abstract class ImportExportEvent extends Equatable {
  const ImportExportEvent();
  @override
  List<Object> get props => [];
}

class ImportClicked extends ImportExportEvent {
  const ImportClicked();
}

class ExportClicked extends ImportExportEvent {
  const ExportClicked();
}

abstract class ImportExportState extends Equatable {
  const ImportExportState();
  @override
  List<Object> get props => [];
}

class ImportExportFinished extends ImportExportState {
  const ImportExportFinished();
}

class ImportExportInitial extends ImportExportState {
  const ImportExportInitial();
}

class ImportExportBloc extends Bloc<ImportExportEvent, ImportExportState> {
  final HiveRepository hive;
  ImportExportBloc(this.hive) : super(const ImportExportInitial()) {
    on<ImportClicked>((event, emit) async {
      await hive.importFile();
      hive.cacheInitialData();
      emit(const ImportExportFinished());
    });
    on<ExportClicked>((event, emit) async {
      await hive.exportFile();
      emit(const ImportExportFinished());
    });
  }
}
