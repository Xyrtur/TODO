import 'package:flutter/material.dart';
import 'package:todo/blocs/blocs_barrel.dart';
import 'package:todo/utils/centre.dart';
import 'package:todo/widgets/svg_button.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Centre.darkerDialogBgColor,
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: SizedBox(
        height: Centre.safeBlockVertical * 15,
        width: Centre.safeBlockHorizontal * 13,
        child: Column(
          children: [
            GestureDetector(
                onTap: () {
                  showLicensePage(context: context, applicationName: "//TODO:");
                },
                child: SizedBox(
                  height: Centre.safeBlockHorizontal * 9,
                  width: Centre.safeBlockHorizontal * 9,
                  child: Icon(
                    Icons.info_outline,
                    color: Centre.primaryColor,
                    size: Centre.safeBlockHorizontal * 7,
                  ),
                )),
            BlocListener<ImportExportBloc, ImportExportState>(
              listener: (context, state) {
                if (state is ImportFinished) {
                  context.read<TodoBloc>().add(TodoDateChange(date: context.read<DateCubit>().state));
                  context.read<UnfinishedListBloc>().add(const UnfinishedListUpdate());
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Centre.dialogBgColor,
                    content: Text(
                      'Import Success!',
                      style: Centre.dialogText,
                    ),
                    duration: const Duration(seconds: 2),
                  ));
                } else if (state is ExportFinished) {
                  if (state.path != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Centre.dialogBgColor,
                      content: Text(
                        "Saved to ${state.path}. Please move the file out",
                        style: Centre.dialogText,
                      ),
                      duration: const Duration(seconds: 5),
                    ));
                  }
                }
              },
              child: GestureDetector(
                onTap: () async {
                  if (Theme.of(context).platform == TargetPlatform.iOS) {
                    context.read<ImportExportBloc>().add(const ImportClicked(false));
                  } else if (Theme.of(context).platform == TargetPlatform.android) {
                    context.read<ImportExportBloc>().add(const ImportClicked(true));
                  }
                },
                child: svgButton(
                  name: "import",
                  color: Centre.yellow,
                  height: 5,
                  width: 5,
                  padding: EdgeInsets.all(Centre.safeBlockHorizontal),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (Theme.of(context).platform == TargetPlatform.iOS) {
                  context.read<ImportExportBloc>().add(const ExportClicked(false));
                } else if (Theme.of(context).platform == TargetPlatform.android) {
                  context.read<ImportExportBloc>().add(const ExportClicked(true));
                }
              },
              child: svgButton(
                name: "export",
                color: Centre.yellow,
                height: 5,
                width: 5,
                padding: EdgeInsets.all(Centre.safeBlockHorizontal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
