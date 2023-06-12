import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loader_overlay/loader_overlay.dart';

import '../data/services/blacklist.dart';
import '../data/services/draft.dart';
import '../data/services/emoticon.dart';
import '../data/services/forum.dart';
import '../data/services/settings.dart';
import '../data/services/user.dart';
import '../utils/backup.dart';
import '../utils/isar.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import '../widgets/dialog.dart';
import '../widgets/list_tile.dart';

class _Selection<T> {
  final T value;

  final RxBool _isSelected = true.obs;

  bool get isSelected => _isSelected.value;

  set isSelected(bool isSelected) => _isSelected.value = isSelected;

  _Selection(this.value);
}

class _BackupDialog extends StatefulWidget {
  // ignore: unused_element
  const _BackupDialog({super.key});

  @override
  State<_BackupDialog> createState() => _BackupDialogState();
}

class _BackupDialogState extends State<_BackupDialog> {
  final List<_Selection<BackupData>> _backups = [
    SettingsBackupData(),
    BlacklistBackupData(),
    PostDraftListBackupData(),
    EmoticonListBackupData(),
    ForumListBackupData(),
    CookiesBackupData(),
    IsarBackupData(),
  ].map((backup) => _Selection(backup)).toList();

  @override
  Widget build(BuildContext context) {
    return LoaderOverlay(
      child: ConfirmCancelDialog(
        title: '备份',
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: _backups
              .map(
                (backup) => Obx(
                  () => TightCheckboxListTile(
                    title: Text(backup.value.title),
                    subtitle: backup.value.subTitle != null
                        ? Text(backup.value.subTitle!)
                        : null,
                    value: backup.isSelected,
                    onChanged: (value) {
                      if (value != null) {
                        backup.isSelected = value;
                      }
                    },
                  ),
                ),
              )
              .toList(),
        ),
        confirmText: '备份',
        onConfirm: () async {
          final backups = _backups
              .where((backup) => backup.isSelected)
              .map((backup) => backup.value)
              .toList();
          if (backups.isEmpty) {
            Get.back();
            return;
          }
          final overlay = context.loaderOverlay;
          final num = 0.obs;

          try {
            showToast('请选择备份文件的保存位置');
            final path =
                await FilePicker.platform.getDirectoryPath(dialogTitle: 'X岛');
            if (path != null) {
              if (GetPlatform.isAndroid && path == '/') {
                throw '获取备份保存文件夹失败';
              } else {
                overlay.show(
                  widget: Center(
                    child: Obx(
                      () => num.value < backups.length
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ValueListenableBuilder(
                                  valueListenable:
                                      backups[num.value].progressListenable,
                                  builder: (context, value, child) => Text(
                                    '正在备份 ${backups[num.value].title} ：'
                                    '${(value * 100.0).toInt()}%',
                                    style: AppTheme.boldRed,
                                  ),
                                ),
                                const SizedBox(height: 5.0),
                                CircularProgressIndicator(
                                  value: num.value / backups.length,
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                );

                await BackupData.backupData(
                    path, backups, (value) => num.value = value);
                showToast('备份成功，请马上重启应用');
              }
            } else {
              debugPrint('用户放弃或者获取备份保存文件夹失败');
            }
          } catch (e) {
            showToast('备份出现错误，请马上重启应用：$e');
          } finally {
            if (overlay.visible) {
              overlay.hide();
            }

            Get.back();
          }
        },
        onCancel: Get.back,
      ),
    );
  }
}

class _Backup extends StatelessWidget {
  // ignore: unused_element
  const _Backup({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('备份应用数据'),
      subtitle: const Text('备份数据时请勿退出或者关闭应用，备份后需要重启应用'),
      onTap: () => Get.dialog(const _BackupDialog()),
    );
  }
}

class BackupView extends StatelessWidget {
  const BackupView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('数据备份与恢复'),
        ),
        body: ListView(
          children: const [_Backup()],
        ),
      );
}
