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
        height: Centre.safeBlockVertical * 18,
        width: Centre.safeBlockHorizontal * 58,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: Centre.safeBlockVertical),
          child: Column(
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
                          child: Icon(
                            Icons.info_outline,
                            color: Centre.colors[3],
                            size: Centre.safeBlockHorizontal * 7,
                          ),
                        ),
                      ),
                      Text(
                        "Licenses",
                        style: Centre.smallerDialogText,
                      )
                    ],
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
                  child: Row(
                    children: [
                      svgButton(
                          name: "import",
                          color: Centre.colors[3],
                          height: 5,
                          width: 5,
                          padding: EdgeInsets.all(Centre.safeBlockHorizontal),
                          margin: EdgeInsets.only(left: Centre.safeBlockHorizontal)),
                      Text(
                        "Import data from zip file",
                        style: Centre.smallerDialogText,
                        maxLines: 2,
                      )
                    ],
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
                child: Row(
                  children: [
                    svgButton(
                        name: "export",
                        color: Centre.colors[3],
                        height: 5,
                        width: 5,
                        padding: EdgeInsets.all(Centre.safeBlockHorizontal),
                        margin: EdgeInsets.only(left: Centre.safeBlockHorizontal)),
                    Text(
                      "Export data to zip file",
                      style: Centre.smallerDialogText,
                      maxLines: 2,
                    )
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
