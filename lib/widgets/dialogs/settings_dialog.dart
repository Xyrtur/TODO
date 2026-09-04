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
        width: Centre.safeBlockHorizontal * 50,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: Centre.safeBlockVertical, horizontal: Centre.safeBlockHorizontal * 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  showLicensePage(context: context, applicationName: "//TODO:");
                },
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: Centre.safeBlockHorizontal),
                      child: SizedBox(
                        height: Centre.safeBlockHorizontal * 9,
                        width: Centre.safeBlockHorizontal * 9,
                        child: Icon(Icons.info_outline, color: Centre.colors[3], size: Centre.safeBlockHorizontal * 7),
                      ),
                    ),
                    Text("Licenses", style: Centre.smallerDialogText),
                  ],
                ),
              ),
              Divider(),
              BlocListener<ImportExportBloc, ImportExportState>(
                listener: (context, state) {
                  if (state is ImportFinished) {
                    context.read<TodoBloc>().add(TodoDateChange(date: context.read<DateCubit>().state));
                    context.read<UnfinishedListBloc>().add(const UnfinishedListUpdate());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Centre.dialogBgColor,
                        content: Text('Import Success!', style: Centre.dialogText),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } else if (state is ExportFinished) {}
                },
                child: GestureDetector(
                  onTap: () async {
                    if (Theme.of(context).platform == TargetPlatform.iOS) {
                      context.read<ImportExportBloc>().add(const ImportClicked(false));
                    } else if (Theme.of(context).platform == TargetPlatform.android) {
                      context.read<ImportExportBloc>().add(const ImportClicked(true));
                    }
                  },
                  child: Row(
                    children: [
                      svgButton(
                        name: "import",
                        color: Centre.colors[3],
                        height: (Centre.safeBlockHorizontal * 1.3).floor(),
                        width: (Centre.safeBlockHorizontal * 1.3).floor(),
                        padding: EdgeInsets.all(Centre.safeBlockHorizontal),
                        margin: EdgeInsets.only(left: Centre.safeBlockHorizontal),
                      ),
                      Text("Import from zip", style: Centre.smallerDialogText, maxLines: 2),
                    ],
                  ),
                ),
              ),
              Divider(),

              GestureDetector(
                onTap: () {
                  if (Theme.of(context).platform == TargetPlatform.iOS) {
                    context.read<ImportExportBloc>().add(const ExportClicked(false));
                  } else if (Theme.of(context).platform == TargetPlatform.android) {
                    context.read<ImportExportBloc>().add(const ExportClicked(true));
                  }
                },
                child: Row(
                  children: [
                    svgButton(
                      name: "export",
                      color: Centre.colors[3],
                      height: (Centre.safeBlockHorizontal * 1.3).floor(),
                      width: (Centre.safeBlockHorizontal * 1.3).floor(),
                      padding: EdgeInsets.all(Centre.safeBlockHorizontal),
                      margin: EdgeInsets.only(left: Centre.safeBlockHorizontal),
                    ),
                    Text("Export to zip", style: Centre.smallerDialogText, maxLines: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
