import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/services/blacklist.dart';
import '../data/services/draft.dart';
import '../data/services/emoticon.dart';
import '../data/services/forum.dart';
import '../data/services/image.dart';
import '../data/services/settings.dart';
import '../data/services/tag.dart';
import '../data/services/user.dart';
import '../utils/backup.dart';
import '../utils/extensions.dart';
import '../utils/history.dart';
import '../utils/isar.dart';
import '../utils/reference.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import '../widgets/dialog.dart';
import '../widgets/list_tile.dart';

/// Android 11或以上版本需要`MANAGE_EXTERNAL_STORAGE`权限
///
/// 返回是否成功获取权限
Future<bool> _requestStoragePermission() async {
  if (GetPlatform.isAndroid &&
      (await DeviceInfoPlugin().androidInfo).version.sdkInt >= 30) {
    PermissionStatus status = await Permission.manageExternalStorage.status;
    if (status.isDenied) {
      showToast('请授予应用相应存储权限');
      status = await Permission.manageExternalStorage.request();
    }

    return status.isGranted;
  }

  return ImageService.to.hasStoragePermission;
}

void _showDialog(String text) => WidgetsBinding.instance
    .addPostFrameCallback((timeStamp) => Get.dialog(ConfirmCancelDialog(
          contentWidget: Text(text, style: AppTheme.boldRed),
          onConfirm: Get.back,
        )));

class _Selection<T> {
  final T value;

  final RxBool _isSelected = true.obs;

  bool isVisible = true;

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
  Widget build(BuildContext context) => LoaderOverlay(
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

                  final file = await BackupData.backupData(
                      path, backups, (value) => num.value = value);
                  _showDialog('备份应用数据成功，请马上重启应用，备份文件保存在 $file');
                }
              } else {
                debugPrint('用户放弃或者获取备份保存文件夹失败');
              }
            } catch (e) {
              _showDialog('备份应用数据出现错误，请马上重启应用：$e');
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

class _Backup extends StatelessWidget {
  // ignore: unused_element
  const _Backup({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
        title: const Text('备份应用数据'),
        subtitle: const Text('只支持保存备份数据在内部存储，备份数据时请勿退出或者关闭应用，备份后需要重启应用'),
        onTap: () async {
          if (!BackupData.isBackup && !RestoreData.isRestored) {
            if (await _requestStoragePermission()) {
              Get.dialog(const _BackupDialog());
            } else {
              showToast('没有存储权限无法备份应用数据');
            }
          } else {
            showToast('请重启应用后再备份应用数据');
          }
        },
      );
}

class _RestoreDialog extends StatefulWidget {
  final String backupDir;

  // ignore: unused_element
  const _RestoreDialog({super.key, required this.backupDir});

  @override
  State<_RestoreDialog> createState() => _RestoreDialogState();
}

class _RestoreDialogState extends State<_RestoreDialog> {
  final List<_Selection<RestoreData>> _restores = [
    SettingsRestoreData(),
    FeedIdRestoreData(),
    ForumBlacklistRestoreData(),
    PostBlacklistRestoreData(),
    UserBlacklistRestoreData(),
    PostDraftListRestoreData(),
    EmoticonListRestoreData(),
    ForumListRestoreData(),
    CookiesRestoreData(),
    BrowseDataHistoryRestoreData(),
    PostHistoryRestoreData(),
    ReplyHistoryRestoreData(),
    TagRestoreData(),
    ReferencesRestoreData(),
  ].map((restore) => _Selection(restore)).toList();

  late Future<List<_Selection<RestoreData>>> _check;

  void _setCheck() => _check = Future(() async {
        for (final restore in _restores) {
          restore.isVisible = await restore.value.canRestore(widget.backupDir);
        }

        return _restores.where((restore) => restore.isVisible).toList();
      });

  @override
  void initState() {
    super.initState();

    _setCheck();
  }

  @override
  void didUpdateWidget(covariant _RestoreDialog oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.backupDir != oldWidget.backupDir) {
      _setCheck();
    }
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<_Selection<RestoreData>>>(
        future: _check,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            final restoreList = snapshot.data!;

            if (restoreList.isEmpty) {
              return ConfirmCancelDialog(
                contentWidget: const Text('无效的应用备份数据', style: AppTheme.boldRed),
                onConfirm: Get.back,
              );
            }

            return LoaderOverlay(
              child: ConfirmCancelDialog(
                title: '恢复',
                contentWidget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: restoreList
                      .map(
                        (restore) => Obx(
                          () => TightCheckboxListTile(
                            title: Text(restore.value.title),
                            subtitle: restore.value.subTitle != null
                                ? Text(restore.value.subTitle!)
                                : null,
                            value: restore.isSelected,
                            onChanged: (value) {
                              if (value != null) {
                                restore.isSelected = value;
                              }
                            },
                          ),
                        ),
                      )
                      .toList(),
                ),
                confirmText: '恢复',
                onConfirm: () async {
                  final restores = restoreList
                      .where((restore) => restore.isSelected)
                      .map((restore) => restore.value)
                      .toList();
                  if (restores.isEmpty) {
                    Get.back();
                    return;
                  }
                  final overlay = context.loaderOverlay;
                  final num = 0.obs;

                  try {
                    overlay.show(
                      widget: Center(
                        child: Obx(
                          () => num.value < restores.length
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ValueListenableBuilder(
                                      valueListenable: restores[num.value]
                                          .progressListenable,
                                      builder: (context, value, child) => Text(
                                        '正在恢复 ${restores[num.value].title} ：'
                                        '${(value * 100.0).toInt()}%',
                                        style: AppTheme.boldRed,
                                      ),
                                    ),
                                    const SizedBox(height: 5.0),
                                    CircularProgressIndicator(
                                      value: num.value / restores.length,
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    );

                    final errors = await RestoreData.restoreData(
                        widget.backupDir,
                        restores,
                        (value) => num.value = value);
                    if (errors.isNotEmpty) {
                      final text = errors.map((error) {
                        final (restore, e) = error;

                        return '恢复 ${restore.title} 的数据出现错误：$e';
                      }).followedBy([
                        if (errors.length < restores.length)
                          '其余应用数据恢复成功，请马上重启应用'
                        else
                          '请马上重启应用'
                      ]).join('\n');

                      _showDialog(text);
                    } else {
                      _showDialog('恢复应用数据成功，请马上重启应用');
                    }
                  } catch (e) {
                    _showDialog('恢复应用数据出现错误，请马上重启应用：$e');
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

          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasError) {
            return ConfirmCancelDialog(
              contentWidget: Text('获取应用备份数据文件出现错误：${snapshot.error}',
                  style: AppTheme.boldRed),
              onConfirm: Get.back,
            );
          }

          return const AlertDialog(content: CircularProgressIndicator());
        },
      );
}

class _Restore extends StatelessWidget {
  // ignore: unused_element
  const _Restore({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
        title: const Text('恢复合并应用数据'),
        subtitle: const Text('恢复数据时请勿退出或者关闭应用，恢复后需要重启应用'),
        onTap: () async {
          if (!BackupData.isBackup && !RestoreData.isRestored) {
            if (await _requestStoragePermission()) {
              showToast('请选取应用备份数据');

              try {
                final result = await FilePicker.platform.pickFiles(
                    dialogTitle: 'xdnmb',
                    type: FileType.custom,
                    allowedExtensions: ['zip'],
                    lockParentWindow: true);

                if (result != null) {
                  final path = result.files.single.path;
                  if (path != null) {
                    Directory? backupDir;
                    try {
                      backupDir = await RestoreData.unzipBackupFile(path);

                      await Get.dialog(
                          _RestoreDialog(backupDir: backupDir.path));
                    } catch (e) {
                      showToast('解压缩和恢复应用备份数据出现错误：$e');

                      return;
                    } finally {
                      await backupDir?.deleteIfExist();
                    }
                  } else {
                    showToast('无法获取应用备份数据具体路径');
                  }
                }
              } catch (e) {
                showToast('选取应用备份数据出现错误：$e');
              }
            } else {
              showToast('没有存储权限无法恢复应用数据');
            }
          } else {
            showToast('请重启应用后再恢复应用数据');
          }
        },
      );
}

class BackupView extends StatelessWidget {
  const BackupView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('数据备份与恢复'),
        ),
        body: ListView(
          children: const [_Backup(), _Restore()],
        ),
      );
}
