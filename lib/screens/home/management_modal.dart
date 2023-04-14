// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:adguard_home_manager/functions/compare_versions.dart';
import 'package:adguard_home_manager/functions/time_server_disabled.dart';
import 'package:adguard_home_manager/providers/app_config_provider.dart';
import 'package:adguard_home_manager/services/http_requests.dart';
import 'package:adguard_home_manager/providers/servers_provider.dart';

class ManagementModal extends StatefulWidget {
  const ManagementModal({Key? key}) : super(key: key);

  @override
  State<ManagementModal> createState() => _ManagementModalState();
}

class _ManagementModalState extends State<ManagementModal> with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> animation;
  final ExpandableController expandableController = ExpandableController();

  DateTime? currentDeadline;
  Timer? countdown;
  int start = 0;

  @override
  void initState() {
    expandableController.addListener(() async {
      await Future.delayed(const Duration(milliseconds: 200));
      if (expandableController.value == false) {
        animationController.animateTo(0);
      }
      else {
        animationController.animateBack(1);
      }
    });

    animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    )
    ..addListener(() => setState(() => {}));
    animation = Tween(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut
    ));
    
    super.initState();
  }

  @override
  void dispose() {
    if (countdown != null) countdown!.cancel();
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serversProvider = Provider.of<ServersProvider>(context);
    final appConfigProvider = Provider.of<AppConfigProvider>(context);

    void startTimer(DateTime deadline) {
      setState(() {
        currentDeadline = deadline;
        start = deadline.difference(DateTime.now()).inSeconds+1;
      });

      const oneSec = Duration(seconds: 1);
      countdown = Timer.periodic(
        oneSec,
        (Timer timer) async {
          if (start == 0) {
            setState(() {
              timer.cancel();
            });
            final result = await getServerStatus(serversProvider.selectedServer!);
            if (result['result'] == 'success') {
              serversProvider.setServerStatusData(result['data']);
            }
          } else {
            setState(() {
              start = start - 1;
            });
          }
        },
      );
    }

    if (
      serversProvider.serverStatus.data != null && 
      serversProvider.serverStatus.data!.disabledUntil != null && 
      serversProvider.serverStatus.data!.disabledUntil != currentDeadline
    ) {
      startTimer(serversProvider.serverStatus.data!.disabledUntil!);
    }

    if (
      serversProvider.serverStatus.data != null && 
      serversProvider.serverStatus.data!.generalEnabled == true
    ) {
      setState(() {
        start = 0;
        currentDeadline = null;
        if (countdown != null) countdown!.cancel();
        countdown = null;
      });
    }

    void updateBlocking({
      required bool value, 
      required String filter,
      int? time
    }) async {
      final result = await serversProvider.updateBlocking(
        server: serversProvider.selectedServer!,
        block: filter, 
        newStatus: value,
        time: time
      );
      if (result != null) {
        if (result != false) {
          appConfigProvider.addLog(result['log']);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.invalidUsernamePassword),
            backgroundColor: Colors.red,
          )
        );
      }
    }

    void disableWithCountdown(int time) async {
      updateBlocking(value: false, filter: 'general', time: time);
      expandableController.toggle();
    }

    Widget mainSwitch() {
      Widget topRow(bool legacyMode) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (legacyMode == true) ...[
                  RotationTransition(
                    turns: animation,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 26,
                      color: serversProvider.serverStatus.data!.generalEnabled == true
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.allProtections,
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                    ),
                    if (serversProvider.serverStatus.data!.timeGeneralDisabled > 0) ...[
                      const SizedBox(height: 2),
                      if (currentDeadline != null) Text(
                        "${AppLocalizations.of(context)!.remainingTime}: ${generateRemainingTimeString(currentDeadline!.difference(DateTime.now()))}"
                      )
                    ]
                  ],
                ),
              ],
            ),
            Switch(
              value: serversProvider.serverStatus.data!.generalEnabled, 
              onChanged: serversProvider.protectionsManagementProcess.contains('general') == false
                ? (value) {
                  if (value == false) {
                    expandableController.toggle();
                  }
                  updateBlocking(
                    value: value, 
                    filter: legacyMode == true ? 'general_legacy' : 'general'
                  );
                } : null,
            )
          ]
        );
      }

      Widget bottomRow() {
        return Container(
          height: 40,
          margin: const EdgeInsets.only(top: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ActionChip(
                label: Text(AppLocalizations.of(context)!.seconds(30)),
                onPressed: serversProvider.protectionsManagementProcess.contains('general') == false
                  ? () => disableWithCountdown(29000)
                  : null,
              ),
              const SizedBox(width: 8),
              ActionChip(
                label: Text(AppLocalizations.of(context)!.minute(1)),
                onPressed: serversProvider.protectionsManagementProcess.contains('general') == false
                  ? () => disableWithCountdown(59000)
                  : null,
              ),
              const SizedBox(width: 8),
              ActionChip(
                label: Text(AppLocalizations.of(context)!.minutes(10)),
                onPressed: serversProvider.protectionsManagementProcess.contains('general') == false
                  ? () => disableWithCountdown(599000)
                  : null,
              ),
              const SizedBox(width: 8),
              ActionChip(
                label: Text(AppLocalizations.of(context)!.hour(1)),
                onPressed: serversProvider.protectionsManagementProcess.contains('general') == false
                  ? () => disableWithCountdown(3599000)
                  : null,
              ),
              const SizedBox(width: 8),
              ActionChip(
                label: Text(AppLocalizations.of(context)!.hours(24)),
                onPressed: serversProvider.protectionsManagementProcess.contains('general') == false
                  ? () => disableWithCountdown(86399000)
                  : null,
              ),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: versionIsGreater(
          currentVersion: serversProvider.serverStatus.data!.serverVersion, 
          referenceVersion: 'v0.107.28',
          referenceVersionBeta: 'v0.108.0-b.33'
        ) == true
          ? ExpandableNotifier(
              controller: expandableController,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  onTap: serversProvider.serverStatus.data!.generalEnabled == true
                    ? () => expandableController.toggle()
                    : null,
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: Theme.of(context).primaryColor.withOpacity(0.1)
                    ),
                    child: Expandable(
                      theme: const ExpandableThemeData(
                        animationDuration: Duration(milliseconds: 200),
                        fadeCurve: Curves.ease
                      ),
                      collapsed: topRow(true), 
                      expanded: Column(
                        children: [
                          topRow(true),
                          bottomRow(),
                          const SizedBox(height: 8)
                        ],
                      )
                    ),
                  ),
                ),
              )
            )
          : Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(28),
              child: InkWell(
                onTap: serversProvider.protectionsManagementProcess.contains('general') == false
                  ? () => updateBlocking(
                    value: !serversProvider.serverStatus.data!.generalEnabled, 
                    filter: 'general_legacy'
                  ) : null,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: Theme.of(context).primaryColor.withOpacity(0.1)
                  ),
                  child: topRow(false)
                ),
              ),
            )
      );
    }

    Widget smallSwitch(String label, IconData icon, bool value, Function(bool) onChange, bool disabled) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled == false
            ? () => onChange(!value)
            : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 44,
              vertical: 8
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 24,
                      color: Theme.of(context).listTileTheme.iconColor,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: value, 
                  onChanged: disabled == false
                    ? onChange
                    : null,
                )
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28)
          )
        ),
        child: Wrap(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Icon(
                      Icons.shield_rounded,
                      size: 24,
                      color: Theme.of(context).listTileTheme.iconColor
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      AppLocalizations.of(context)!.manageServer,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  ],
                ),
              ],
            ),
            mainSwitch(),
            const SizedBox(height: 10),
            smallSwitch(
              AppLocalizations.of(context)!.ruleFiltering,
              Icons.filter_list_rounded,
              serversProvider.serverStatus.data!.filteringEnabled, 
              (value) => updateBlocking(value: value, filter: 'filtering'),
              serversProvider.protectionsManagementProcess.contains('filtering')
            ),
            smallSwitch(
              AppLocalizations.of(context)!.safeBrowsing,
              Icons.vpn_lock_rounded,
              serversProvider.serverStatus.data!.safeBrowsingEnabled, 
              (value) => updateBlocking(value: value, filter: 'safeBrowsing'),
              serversProvider.protectionsManagementProcess.contains('safeBrowsing')
            ),
            smallSwitch(
              AppLocalizations.of(context)!.parentalFiltering,
              Icons.block,
              serversProvider.serverStatus.data!.parentalControlEnabled, 
              (value) => updateBlocking(value: value, filter: 'parentalControl'),
              serversProvider.protectionsManagementProcess.contains('parentalControl')
            ),
            smallSwitch(
              AppLocalizations.of(context)!.safeSearch,
              Icons.search_rounded,
              serversProvider.serverStatus.data!.safeSearchEnabled, 
              (value) => updateBlocking(value: value, filter: 'safeSearch'),
              serversProvider.protectionsManagementProcess.contains('safeSearch')
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context), 
                    child: Text(AppLocalizations.of(context)!.close),
                  ),
                ],
              ),
            ),
            if (Platform.isIOS) const SizedBox(height: 16)
          ],
        ),
      ),
    );
  }
}