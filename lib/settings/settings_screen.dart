/*
Copyright 2020-2021 Vishesh Handa <me@vhanda.in>
                    Roland Fredenhagen <important@van-fredenhagen.de>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:email_validator/email_validator.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:icloud_documents_path/icloud_documents_path.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:universal_io/io.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gitjournal/analytics/analytics.dart';
import 'package:gitjournal/core/notes_folder_config.dart';
import 'package:gitjournal/core/notes_folder_fs.dart';
import 'package:gitjournal/features.dart';
import 'package:gitjournal/generated/locale_keys.g.dart';
import 'package:gitjournal/logger/debug_screen.dart';
import 'package:gitjournal/logger/logger.dart';
import 'package:gitjournal/repository.dart';
import 'package:gitjournal/repository_manager.dart';
import 'package:gitjournal/screens/feature_timeline_screen.dart';
import 'package:gitjournal/settings/app_settings.dart';
import 'package:gitjournal/settings/git_config.dart';
import 'package:gitjournal/settings/settings.dart';
import 'package:gitjournal/settings/settings_bottom_menu_bar.dart';
import 'package:gitjournal/settings/settings_display_images.dart';
import 'package:gitjournal/settings/settings_editors.dart';
import 'package:gitjournal/settings/settings_experimental.dart';
import 'package:gitjournal/settings/settings_git_remote.dart';
import 'package:gitjournal/settings/settings_images.dart';
import 'package:gitjournal/settings/settings_misc.dart';
import 'package:gitjournal/settings/settings_note_metadata.dart';
import 'package:gitjournal/settings/settings_tags.dart';
import 'package:gitjournal/settings/settings_widgets.dart';
import 'package:gitjournal/settings/storage_config.dart';
import 'package:gitjournal/utils/utils.dart';
import 'package:gitjournal/widgets/folder_selection_dialog.dart';
import 'package:gitjournal/widgets/pro_overlay.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(LocaleKeys.settings_title)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SettingsList(),
    );
  }
}

class SettingsList extends StatefulWidget {
  @override
  SettingsListState createState() {
    return SettingsListState();
  }
}

class SettingsListState extends State<SettingsList> {
  final gitAuthorKey = GlobalKey<FormFieldState<String>>();
  final gitAuthorEmailKey = GlobalKey<FormFieldState<String>>();
  final fontSizeKey = GlobalKey<FormFieldState<String>>();

  @override
  Widget build(BuildContext context) {
    var settings = Provider.of<Settings>(context);
    var gitConfig = Provider.of<GitConfig>(context);
    var storageConfig = Provider.of<StorageConfig>(context);
    var appSettings = Provider.of<AppSettings>(context);
    final repo = Provider.of<GitJournalRepo>(context);
    var repoManager = Provider.of<RepositoryManager>(context);

    var saveGitAuthor = (String? gitAuthor) {
      if (gitAuthor == null) return;
      gitConfig.gitAuthor = gitAuthor;
      gitConfig.save();
    };

    var gitAuthorForm = Form(
      child: TextFormField(
        key: gitAuthorKey,
        style: Theme.of(context).textTheme.headline6,
        decoration: InputDecoration(
          icon: const Icon(Icons.person),
          hintText: tr(LocaleKeys.settings_author_hint),
          labelText: tr(LocaleKeys.settings_author_label),
        ),
        validator: (String? value) {
          value = value!.trim();
          if (value.isEmpty) {
            return tr(LocaleKeys.settings_author_validator);
          }
          return null;
        },
        textInputAction: TextInputAction.done,
        onFieldSubmitted: saveGitAuthor,
        onSaved: saveGitAuthor,
        initialValue: gitConfig.gitAuthor,
      ),
      onChanged: () {
        if (!gitAuthorKey.currentState!.validate()) return;
        var gitAuthor = gitAuthorKey.currentState!.value;
        saveGitAuthor(gitAuthor);
      },
    );

    var saveGitAuthorEmail = (String? gitAuthorEmail) {
      if (gitAuthorEmail == null) return;

      gitConfig.gitAuthorEmail = gitAuthorEmail;
      gitConfig.save();
    };
    var gitAuthorEmailForm = Form(
      child: TextFormField(
        key: gitAuthorEmailKey,
        style: Theme.of(context).textTheme.headline6,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          icon: const Icon(Icons.email),
          hintText: tr(LocaleKeys.settings_email_hint),
          labelText: tr(LocaleKeys.settings_email_label),
        ),
        validator: (String? value) {
          value = value!.trim();
          if (value.isEmpty) {
            return tr(LocaleKeys.settings_email_validator_empty);
          }

          if (!EmailValidator.validate(value)) {
            return tr(LocaleKeys.settings_email_validator_invalid);
          }
          return null;
        },
        textInputAction: TextInputAction.done,
        onFieldSubmitted: saveGitAuthorEmail,
        onSaved: saveGitAuthorEmail,
        initialValue: gitConfig.gitAuthorEmail,
      ),
      onChanged: () {
        if (!gitAuthorEmailKey.currentState!.validate()) return;
        var gitAuthorEmail = gitAuthorEmailKey.currentState!.value;
        saveGitAuthorEmail(gitAuthorEmail);
      },
    );

    var defaultNewFolder = settings.defaultNewNoteFolderSpec;
    if (defaultNewFolder.isEmpty) {
      defaultNewFolder = tr(LocaleKeys.rootFolder);
    } else {
      if (!folderWithSpecExists(context, defaultNewFolder)) {
        setState(() {
          defaultNewFolder = tr(LocaleKeys.rootFolder);

          settings.defaultNewNoteFolderSpec = "";
          settings.save();
        });
      }
    }

    var easyLocale = EasyLocalization.of(context)!;
    var folderConfig = Provider.of<NotesFolderConfig>(context);

    return ListView(children: [
      SettingsHeader(tr(LocaleKeys.settings_display_title)),
      ListPreference(
        title: tr(LocaleKeys.settings_display_theme),
        currentOption: settings.theme.toPublicString(),
        options: SettingsTheme.options.map((f) => f.toPublicString()).toList(),
        onChange: (String publicStr) {
          var s = SettingsTheme.fromPublicString(publicStr);
          settings.theme = s;
          settings.save();
          setState(() {});
        },
      ),
      ListPreference(
        title: tr(LocaleKeys.settings_display_lang),
        currentOption: easyLocale.currentLocale?.toLanguageTag(),
        options:
            easyLocale.supportedLocales.map((f) => f.toLanguageTag()).toList(),
        onChange: (String langTag) {
          var locale = easyLocale.supportedLocales
              .firstWhere((e) => e.toLanguageTag() == langTag);
          easyLocale.setLocale(locale);
        },
      ),
      ListTile(
        title: Text(tr(LocaleKeys.settings_display_images_title)),
        subtitle: Text(tr(LocaleKeys.settings_display_images_subtitle)),
        onTap: () {
          var route = MaterialPageRoute(
            builder: (context) => SettingsDisplayImagesScreen(),
            settings: const RouteSettings(name: '/settings/display_images'),
          );
          Navigator.of(context).push(route);
        },
      ),
      ProOverlay(
        feature: Feature.customizeHomeScreen,
        child: ListPreference(
          title: tr(LocaleKeys.settings_display_homeScreen),
          currentOption: settings.homeScreen.toPublicString(),
          options: SettingsHomeScreen.options
              .map((f) => f.toPublicString())
              .toList(),
          onChange: (String publicStr) {
            var s = SettingsHomeScreen.fromPublicString(publicStr);
            settings.homeScreen = s;
            settings.save();
            setState(() {});
          },
        ),
      ),
      ProOverlay(
        feature: Feature.configureBottomMenuBar,
        child: ListTile(
          title: Text(tr(LocaleKeys.settings_bottomMenuBar_title)),
          subtitle: Text(tr(LocaleKeys.settings_bottomMenuBar_subtitle)),
          onTap: () {
            var route = MaterialPageRoute(
              builder: (context) => BottomMenuBarSettings(),
              settings: const RouteSettings(name: '/settings/bottom_menu_bar'),
            );
            Navigator.of(context).push(route);
          },
        ),
      ),
      SettingsHeader(tr(LocaleKeys.settings_note_title)),
      ListTile(
        title: Text(tr(LocaleKeys.settings_note_defaultFolder)),
        subtitle: Text(defaultNewFolder),
        onTap: () async {
          var destFolder = await showDialog<NotesFolderFS>(
            context: context,
            builder: (context) => FolderSelectionDialog(),
          );
          if (destFolder != null) {
            settings.defaultNewNoteFolderSpec = destFolder.pathSpec();
            settings.save();
            setState(() {});
          }
        },
      ),
      SettingsHeader(tr(LocaleKeys.settings_gitAuthor)),
      ListTile(title: gitAuthorForm),
      ListTile(title: gitAuthorEmailForm),
      ListTile(
        title: Text(tr(LocaleKeys.settings_gitRemote_title)),
        subtitle: Text(tr(LocaleKeys.settings_gitRemote_subtitle)),
        onTap: () {
          var route = MaterialPageRoute(
            builder: (context) =>
                GitRemoteSettingsScreen(gitConfig.sshPublicKey),
            settings: const RouteSettings(name: '/settings/gitRemote'),
          );
          Navigator.of(context).push(route);
        },
        enabled: repo.remoteGitRepoConfigured,
      ),
      const SizedBox(height: 16.0),
      ListTile(
        title: Text(tr(LocaleKeys.settings_editors_title)),
        subtitle: Text(tr(LocaleKeys.settings_editors_subtitle)),
        onTap: () {
          var route = MaterialPageRoute(
            builder: (context) => SettingsEditorsScreen(),
            settings: const RouteSettings(name: '/settings/editors'),
          );
          Navigator.of(context).push(route);
        },
      ),
      SettingsHeader(tr(LocaleKeys.settings_storage_title)),
      ListPreference(
        title: tr(LocaleKeys.settings_note_newNoteFileName),
        currentOption: folderConfig.fileNameFormat.toPublicString(),
        options:
            NoteFileNameFormat.options.map((f) => f.toPublicString()).toList(),
        onChange: (String publicStr) {
          var format = NoteFileNameFormat.fromPublicString(publicStr);
          folderConfig.fileNameFormat = format;
          folderConfig.save();
          setState(() {});
        },
      ),
      ListTile(
        title: Text(tr(LocaleKeys.settings_noteMetaData_title)),
        subtitle: Text(tr(LocaleKeys.settings_noteMetaData_subtitle)),
        onTap: () {
          var route = MaterialPageRoute(
            builder: (context) => NoteMetadataSettingsScreen(),
            settings: const RouteSettings(name: '/settings/noteMetaData'),
          );
          Navigator.of(context).push(route);
        },
      ),
      ProOverlay(
        feature: Feature.inlineTags,
        child: ListTile(
          title: Text(tr(LocaleKeys.settings_tags_title)),
          subtitle: Text(tr(LocaleKeys.settings_tags_subtitle)),
          onTap: () {
            var route = MaterialPageRoute(
              builder: (context) => SettingsTagsScreen(),
              settings: const RouteSettings(name: '/settings/tags'),
            );
            Navigator.of(context).push(route);
          },
        ),
      ),
      ListTile(
        title: Text(tr(LocaleKeys.settings_misc_title)),
        subtitle: Text(tr(LocaleKeys.settings_images_subtitle)),
        onTap: () {
          var route = MaterialPageRoute(
            builder: (context) => SettingsImagesScreen(),
            settings: const RouteSettings(name: '/settings/images'),
          );
          Navigator.of(context).push(route);
        },
      ),
      if (Platform.isAndroid)
        SwitchListTile(
          title: Text(tr(LocaleKeys.settings_storage_external)),
          value: !storageConfig.storeInternally,
          onChanged: (bool newVal) async {
            Future<void> moveBackToInternal(bool showError) async {
              storageConfig.storeInternally = true;
              storageConfig.storageLocation = "";

              storageConfig.save();
              setState(() {});
              await repo.moveRepoToPath();

              if (showError) {
                showSnackbar(
                  context,
                  LocaleKeys.settings_storage_failedExternal,
                );
              }
            }

            if (newVal == false) {
              await moveBackToInternal(false);
            } else {
              var path = await _getExternalDir(context);
              if (path.isEmpty) {
                await moveBackToInternal(true);
                return;
              }

              Log.i("Moving repo to $path");

              storageConfig.storeInternally = false;
              storageConfig.storageLocation = p.join(path, "GitJournal");
              storageConfig.save();
              setState(() {});

              try {
                await repo.moveRepoToPath();
              } catch (ex, st) {
                Log.e("Moving Repo to External Storage",
                    ex: ex, stacktrace: st);
                await moveBackToInternal(true);
                return;
              }
              return;
            }
          },
        ),
      if (Platform.isAndroid)
        ListTile(
          title: Text(tr(LocaleKeys.settings_storage_repoLocation)),
          subtitle: Text(
              p.join(storageConfig.storageLocation, storageConfig.folderName)),
          enabled: !storageConfig.storeInternally,
        ),
      if (Platform.isIOS)
        SwitchListTile(
          title: Text(tr(LocaleKeys.settings_storage_icloud)),
          value: !storageConfig.storeInternally,
          onChanged: (bool newVal) async {
            if (newVal == false) {
              storageConfig.storeInternally = true;
              storageConfig.storageLocation = "";
            } else {
              storageConfig.storageLocation =
                  (await ICloudDocumentsPath.documentsPath)!;
              if (storageConfig.storageLocation.isNotEmpty) {
                storageConfig.storeInternally = false;
              }
            }
            settings.save();
            repo.moveRepoToPath();

            setState(() {});
          },
        ),
      ListTile(
        title: Text(tr(LocaleKeys.settings_misc_title)),
        onTap: () {
          var route = MaterialPageRoute(
            builder: (context) => SettingsMisc(),
            settings: const RouteSettings(name: '/settings/misc'),
          );
          Navigator.of(context).push(route);
        },
      ),
      if (repoManager.repoIds.length > 1)
        RedButton(
          text: tr(LocaleKeys.settings_deleteRepo),
          onPressed: () async {
            var ok = await showDialog(
              context: context,
              builder: (_) => IrreversibleActionConfirmationDialog(
                tr(LocaleKeys.settings_deleteRepo),
              ),
            );
            if (ok == null) {
              return;
            }

            var repoManager = context.read<RepositoryManager>();
            await repoManager.deleteCurrent();

            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      const SizedBox(height: 16.0),
      ListTile(
        title: Text(tr(LocaleKeys.feature_timeline_title)),
        onTap: () {
          var route = MaterialPageRoute(
            builder: (context) => FeatureTimelineScreen(),
            settings: const RouteSettings(name: '/featureTimeline'),
          );
          Navigator.of(context).push(route);
        },
      ),
      const SizedBox(height: 16.0),
      if (Analytics.instance != null)
        SwitchListTile(
          title: Text(tr(LocaleKeys.settings_usageStats)),
          value: Analytics.instance!.config.enabled,
          onChanged: (bool val) {
            Analytics.instance!.enabled = val;
            setState(() {}); // Remove this once Analytics.instace is not used
          },
        ),
      SwitchListTile(
        title: Text(tr(LocaleKeys.settings_crashReports)),
        value: appSettings.collectCrashReports,
        onChanged: (bool val) {
          appSettings.collectCrashReports = val;
          appSettings.save();
          setState(() {});

          logEvent(
            Event.CrashReportingLevelChanged,
            parameters: {"state": val.toString()},
          );
        },
      ),
      VersionNumberTile(),
      ListTile(
        title: Text(tr(LocaleKeys.settings_debug_title)),
        subtitle: Text(tr(LocaleKeys.settings_debug_subtitle)),
        onTap: () {
          var route = MaterialPageRoute(
            builder: (context) => DebugScreen(),
            settings: const RouteSettings(name: '/settings/debug'),
          );
          Navigator.of(context).push(route);
        },
      ),
      ListTile(
        title: Text(tr(LocaleKeys.settings_experimental_title)),
        subtitle: Text(tr(LocaleKeys.settings_experimental_subtitle)),
        onTap: () {
          var route = MaterialPageRoute(
            builder: (context) => ExperimentalSettingsScreen(),
            settings: const RouteSettings(name: '/settings/experimental'),
          );
          Navigator.of(context).push(route);
        },
      ),
      ListTile(
        title: Text(tr(LocaleKeys.settings_privacy)),
        onTap: () {
          launch("https://gitjournal.io/privacy");
        },
      ),
      ListTile(
        title: Text(tr(LocaleKeys.settings_terms)),
        onTap: () {
          launch("https://gitjournal.io/terms");
        },
      ),
    ]);
  }
}

class SettingsHeader extends StatelessWidget {
  final String text;
  SettingsHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 0.0, top: 20.0),
      child: Text(
        text,
        style: TextStyle(
            color: Theme.of(context).accentColor, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class VersionNumberTile extends StatefulWidget {
  @override
  VersionNumberTileState createState() {
    return VersionNumberTileState();
  }
}

class VersionNumberTileState extends State<VersionNumberTile> {
  String versionText = "";

  @override
  void initState() {
    super.initState();

    () async {
      var str = await getVersionString();
      if (!mounted) return;
      setState(() {
        versionText = str;
      });
    }();
  }

  @override
  Widget build(BuildContext context) {
    var textTheme = Theme.of(context).textTheme;
    return ListTile(
      title:
          Text(tr(LocaleKeys.settings_versionInfo), style: textTheme.subtitle1),
      subtitle: Text(
        versionText,
        style: textTheme.bodyText2,
        textAlign: TextAlign.left,
      ),
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: versionText));
        showSnackbar(context, tr(LocaleKeys.settings_versionCopied));
      },
    );
  }
}

Future<bool> _isDirWritable(String path) async {
  var fileName = DateTime.now().millisecondsSinceEpoch.toString();
  var file = File(p.join(path, fileName));

  try {
    await file.writeAsString("test");
    await file.delete();
  } catch (_) {
    return false;
  }

  return true;
}

Future<String> _getExternalDir(BuildContext context) async {
  if (!await Permission.storage.request().isGranted) {
    return "";
  }

  var dir = await FilePicker.platform.getDirectoryPath();
  if (dir != null && dir.isNotEmpty) {
    if (await _isDirWritable(dir)) {
      return dir;
    } else {
      Log.e("FilePicker: Got $dir but it is not writable");
      showSnackbar(
        context,
        tr(LocaleKeys.settings_storage_notWritable, args: [dir]),
      );
    }
  }

  var req = await Permission.storage.request();
  if (req.isDenied) {
    return "";
  }

  var path = await ExtStorage.getExternalStorageDirectory();
  if (path != null) {
    if (await _isDirWritable(path)) {
      return path;
    } else {
      Log.e("ExtStorage: Got $path but it is not writable");
    }
  }

  var extDir = await getExternalStorageDirectory();
  if (extDir != null) {
    path = extDir.path;

    if (await _isDirWritable(path)) {
      return path;
    } else {
      Log.e("ExternalStorageDirectory: Got $path but it is not writable");
    }
  }

  return "";
}
