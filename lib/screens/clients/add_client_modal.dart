import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:adguard_home_manager/screens/clients/services_modal.dart';
import 'package:adguard_home_manager/screens/clients/tags_modal.dart';

import 'package:adguard_home_manager/providers/servers_provider.dart';
import 'package:adguard_home_manager/models/clients.dart';

class AddClientModal extends StatefulWidget {
  final void Function(Client) onConfirm;

  const AddClientModal({
    Key? key,
    required this.onConfirm
  }) : super(key: key);

  @override
  State<AddClientModal> createState() => _AddClientModalState();
}

class _AddClientModalState extends State<AddClientModal> {
  final Uuid uuid = const Uuid();

  TextEditingController nameController = TextEditingController();

  List<String> selectedTags = [];

  List<Map<dynamic, dynamic>> identifiersControllers = [
    {
      'id': 0,
      'controller': TextEditingController()
    }
  ];

  bool useGlobalSettingsFiltering = true;
  bool? enableFiltering;
  bool? enableSafeBrowsing;
  bool? enableParentalControl;
  bool? enableSafeSearch;

  bool useGlobalSettingsServices = true;
  List<String> blockedServices = [];

  List<Map<dynamic, dynamic>> upstreamServers = [];


  bool checkValidValues() {
    if (
      nameController.text != '' &&
      identifiersControllers.isNotEmpty && 
      identifiersControllers[0]['controller'].text != ''
    ) {
      return true;
    }
    else {
      return false;
    }
  }
    
  @override
  Widget build(BuildContext context) {
    final serversProvider = Provider.of<ServersProvider>(context);

    void createClient() {
      final Client client = Client(
        name: nameController.text, 
        ids: List<String>.from(identifiersControllers.map((e) => e['controller'].text)), 
        useGlobalSettings: useGlobalSettingsFiltering, 
        filteringEnabled: enableFiltering ?? false, 
        parentalEnabled: enableParentalControl ?? false, 
        safebrowsingEnabled: enableSafeBrowsing ?? false, 
        safesearchEnabled: enableSafeSearch ?? false, 
        useGlobalBlockedServices: useGlobalSettingsServices, 
        blockedServices: blockedServices, 
        upstreams: List<String>.from(upstreamServers.map((e) => e['controller'].text)), 
        tags: selectedTags
      );
      widget.onConfirm(client);
    }

    Widget sectionLabel(String label) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 30,
          horizontal: 20
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Theme.of(context).primaryColor
          ),
        ),
      );
    }

    void enableDisableGlobalSettingsFiltering() {
      if (useGlobalSettingsFiltering == true) {
        setState(() {
          useGlobalSettingsFiltering = false;

          enableFiltering = false;
          enableSafeBrowsing = false;
          enableParentalControl = false;
          enableSafeSearch = false;
        });
      }
      else if (useGlobalSettingsFiltering == false) {
        setState(() {
          useGlobalSettingsFiltering = true;
          
          enableFiltering = null;
          enableSafeBrowsing = null;
          enableParentalControl = null;
          enableSafeSearch = null;
        });
      }
    }

    void openTagsModal() {
      showDialog(
        context: context, 
        builder: (context) => TagsModal(
          selectedTags: selectedTags,
          tags: serversProvider.clients.data!.supportedTags,
          onConfirm: (selected) => setState(() => selectedTags = selected),
        )
      );
    }

    void openServicesModal() {
      showDialog(
        context: context, 
        builder: (context) => ServicesModal(
          blockedServices: blockedServices,
          onConfirm: (values) => setState(() => blockedServices = values),
        )
      );
    }

    void updateServicesGlobalSettings(bool value) {
      if (value == true) {
        setState(() {
          blockedServices = [];
          useGlobalSettingsServices = true;
        });
      }
      else if (value == false) {
        setState(() {
          useGlobalSettingsServices = false;
        });
      }
    }

    Widget settignsTile({
      required String label,
      required bool? value,
      required void Function(bool) onChange
    }) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: value != null ? () => onChange(!value) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 30,
              vertical: 5
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15
                  ),
                ),
                value != null 
                  ? Switch(
                      value: value, 
                      onChanged: onChange,
                      activeColor: Theme.of(context).primaryColor,
                    )
                  : const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        "Global",
                        style: TextStyle(
                          color: Colors.grey
                        ),
                      ),
                    )
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, scrollController) =>  Container(
          decoration: BoxDecoration(
            color: Theme.of(context).dialogBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28)
            )
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    const SizedBox(height: 28),
                    const Icon(
                      Icons.add,
                      size: 26,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context)!.addClient,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24
                      ),
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextFormField(
                        controller: nameController,
                        onChanged: (_) => checkValidValues(),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.badge_rounded),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(10)
                            )
                          ),
                          labelText: AppLocalizations.of(context)!.name,
                        ),
                      ),
                    ),
                    sectionLabel(AppLocalizations.of(context)!.tags),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: openTagsModal,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.label_rounded,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.selectTags,
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    selectedTags.isNotEmpty
                                      ? "${selectedTags.length} ${AppLocalizations.of(context)!.tagsSelected}"
                                      : AppLocalizations.of(context)!.noTagsSelected,
                                    style: const TextStyle(
                                      color: Colors.grey
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        sectionLabel(AppLocalizations.of(context)!.identifiers),
                        Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: IconButton(
                            onPressed: () => setState(() => identifiersControllers.add({
                              'id': uuid.v4(),
                              'controller': TextEditingController()
                            })),
                            icon: const Icon(Icons.add)
                          ),
                        )
                      ],
                    ),
                    if (identifiersControllers.isNotEmpty) ...identifiersControllers.map((controller) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width - 108,
                              child: TextFormField(
                                controller: controller['controller'],
                                onChanged: (_) => checkValidValues(),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.tag),
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10)
                                    )
                                  ),
                                  helperText: AppLocalizations.of(context)!.identifierHelper,
                                  labelText: AppLocalizations.of(context)!.identifier,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 25),
                              child: IconButton(
                                onPressed: () => setState(
                                  () => identifiersControllers = identifiersControllers.where((e) => e['id'] != controller['id']).toList()
                                ), 
                                icon: const Icon(Icons.remove_circle_outline_outlined)
                              ),
                            )
                          ],
                        ),
                      ),
                    )).toList(),
                    if (identifiersControllers.isEmpty) Container(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        AppLocalizations.of(context)!.noIdentifiers,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey
                        ),
                      ),
                    ),
                    sectionLabel(AppLocalizations.of(context)!.settings),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Material(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(28),
                        child: InkWell(
                          onTap: enableDisableGlobalSettingsFiltering,
                          borderRadius: BorderRadius.circular(28),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 5
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.useGlobalSettings,
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                                Switch(
                                  value: useGlobalSettingsFiltering, 
                                  onChanged: (value) => enableDisableGlobalSettingsFiltering(),
                                  activeColor: Theme.of(context).primaryColor,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    settignsTile(
                      label: AppLocalizations.of(context)!.enableFiltering,
                      value: enableFiltering, 
                      onChange: (value) => setState(() => enableFiltering = value)
                    ),
                    settignsTile(
                      label: AppLocalizations.of(context)!.enableSafeBrowsing,
                      value: enableSafeBrowsing, 
                      onChange: (value) => setState(() => enableSafeBrowsing = value)
                    ),
                    settignsTile(
                      label: AppLocalizations.of(context)!.enableParentalControl,
                      value: enableParentalControl, 
                      onChange: (value) => setState(() => enableParentalControl = value)
                    ),
                    settignsTile(
                      label: AppLocalizations.of(context)!.enableSafeSearch,
                      value: enableSafeSearch, 
                      onChange: (value) => setState(() => enableSafeSearch = value)
                    ),
                    sectionLabel(AppLocalizations.of(context)!.blockedServices),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Material(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(28),
                        child: InkWell(
                          onTap: () => updateServicesGlobalSettings(!useGlobalSettingsServices),
                          borderRadius: BorderRadius.circular(28),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 5
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.useGlobalSettings,
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                                Switch(
                                  value: useGlobalSettingsServices, 
                                  onChanged: updateServicesGlobalSettings,
                                  activeColor: Theme.of(context).primaryColor,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: useGlobalSettingsServices == false
                          ? openServicesModal
                          : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.public,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.selectBlockedServices,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: useGlobalSettingsServices == false
                                        ? null
                                        : Colors.grey
                                    ),
                                  ),
                                  if (useGlobalSettingsServices == false) ...[
                                    const SizedBox(height: 5),
                                    Text(
                                      blockedServices.isNotEmpty
                                        ? "${blockedServices.length} ${AppLocalizations.of(context)!.servicesBlocked}"
                                        :  AppLocalizations.of(context)!.noBlockedServicesSelected,
                                      style: const TextStyle(
                                        color: Colors.grey
                                      ),
                                    )
                                  ]
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        sectionLabel(AppLocalizations.of(context)!.upstreamServers),
                        Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: IconButton(
                            onPressed: () => setState(() => upstreamServers.add({
                              'id': uuid.v4(),
                              'controller': TextEditingController()
                            })),
                            icon: const Icon(Icons.add)
                          ),
                        )
                      ],
                    ),
                    if (upstreamServers.isNotEmpty) ...upstreamServers.map((controller) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width - 108,
                              child: TextFormField(
                                controller: controller['controller'],
                                onChanged: (_) => checkValidValues(),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.dns_rounded),
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10)
                                    )
                                  ),
                                  labelText: AppLocalizations.of(context)!.serverAddress,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            IconButton(
                              onPressed: () => setState(
                                () => upstreamServers = upstreamServers.where((e) => e['id'] != controller['id']).toList()
                              ), 
                              icon: const Icon(Icons.remove_circle_outline_outlined)
                            )
                          ],
                        ),
                      ),
                    )).toList(),
                    if (upstreamServers.isEmpty) Container(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.noUpstreamServers,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppLocalizations.of(context)!.willBeUsedGeneralServers,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.grey
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context), 
                      child: Text(AppLocalizations.of(context)!.cancel)
                    ),
                    const SizedBox(width: 20),
                    TextButton(
                      onPressed: checkValidValues() == true
                        ? () {
                            createClient();
                            Navigator.pop(context);
                          }
                        : null, 
                      child: Text(
                        AppLocalizations.of(context)!.confirm,
                        style: TextStyle(
                          color: checkValidValues() == true
                            ? Theme.of(context).primaryColor
                            : Colors.grey
                        ),
                      )
                    ),
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