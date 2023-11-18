import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:adguard_home_manager/screens/filters/selection/enable_disable_selection_modal.dart';
import 'package:adguard_home_manager/screens/filters/selection/delete_selection_modal.dart';
import 'package:adguard_home_manager/screens/filters/selection/selection_result_modal.dart';
import 'package:adguard_home_manager/screens/filters/selection/selection_lists.dart';

import 'package:adguard_home_manager/classes/process_modal.dart';
import 'package:adguard_home_manager/models/filtering.dart';
import 'package:adguard_home_manager/providers/filtering_provider.dart';

enum ListType { blacklist, whitelist }

class SelectionScreen extends StatefulWidget {
  final bool isModal;

  const SelectionScreen({
    Key? key,
    required this.isModal
  }) : super(key: key);

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  bool _isScrolled = false;

  List<Filter> _selectedWhitelists = [];
  List<Filter> _selectedBlacklists = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: 0,
      length: 2,
      vsync: this,
    );
    _scrollController = ScrollController()..addListener(() {
      setState(() => _isScrolled = _scrollController.offset > 20);
    });
  }

  void handleSelect(Filter list, ListType type) {
    if (type == ListType.blacklist) {
      final isContained = _selectedBlacklists.contains(list);
      if (isContained) {
        setState(() => _selectedBlacklists = _selectedBlacklists.where((l) => l != list).toList());
      }
      else {
        setState(() => _selectedBlacklists.add(list));
      }
    }
    else if (type == ListType.whitelist) {
      final isContained = _selectedWhitelists.contains(list);
      if (isContained) {
        setState(() => _selectedWhitelists = _selectedWhitelists.where((l) => l != list).toList());
      }
      else {
        setState(() => _selectedWhitelists.add(list));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteringProvider = Provider.of<FilteringProvider>(context);

    final somethingSelected = _selectedBlacklists.isNotEmpty || _selectedWhitelists.isNotEmpty;

    void enableDisableSelected() {
      showDialog(
        context: context, 
        builder: (ctx) => EnableDisableSelectionModal(
          selectedWhitelists: _selectedWhitelists,
          selectedBlacklists: _selectedBlacklists,
          onDelete: () async {
            Navigator.pop(context);
            final processModal = ProcessModal(context: context);
            processModal.open(AppLocalizations.of(context)!.processingLists);
            final result = await filteringProvider.enableDisableMultipleLists(
              blacklists: _selectedBlacklists, 
              whitelists: _selectedWhitelists
            );
            if (!mounted) return;
            processModal.close();
            showDialog(
              context: context, 
              builder: (ctx) => SelectionResultModal(
                mode: SelectionResultMode.enableDisable,
                results: result,
                onClose: () => Navigator.pop(context),
              ),
              barrierDismissible: false
            );
          },
        ),
        barrierDismissible: false
      );
    }

    void deleteSelected() {
      showDialog(
        context: context, 
        builder: (ctx) => DeleteSelectionModal(
          selectedWhitelists: _selectedWhitelists,
          selectedBlacklists: _selectedBlacklists,
          onDelete: () async {
            Navigator.pop(context);
            final processModal = ProcessModal(context: context);
            processModal.open(AppLocalizations.of(context)!.deletingLists);
            final result = await filteringProvider.deleteMultipleLists(
              blacklists: _selectedBlacklists, 
              whitelists: _selectedWhitelists
            );
            if (!mounted) return;
            processModal.close();
            showDialog(
              context: context, 
              builder: (ctx) => SelectionResultModal(
                mode: SelectionResultMode.delete,
                results: result,
                onClose: () => Navigator.pop(context),
              ),
              barrierDismissible: false
            );
          },
        ),
        barrierDismissible: false
      );
    }
    
    if (widget.isModal == true) {
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 500
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.clear_rounded),
                          tooltip: AppLocalizations.of(context)!.close,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.selectionMode,
                          style: const TextStyle(
                            fontSize: 22
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: enableDisableSelected, 
                          icon: const Icon(Icons.shield_rounded),
                          tooltip: AppLocalizations.of(context)!.enableDisableSelected,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: deleteSelected, 
                          icon: const Icon(Icons.delete_rounded),
                          tooltip: AppLocalizations.of(context)!.deleteSelectedLists,
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Expanded(
                child: DefaultTabController(
                  length: 2, 
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        tabs: [
                          _Tab(
                            icon: Icons.verified_user_rounded, 
                            text: AppLocalizations.of(context)!.whitelists, 
                            quantity: _selectedWhitelists.length
                          ),
                          _Tab(
                            icon: Icons.gpp_bad_rounded, 
                            text: AppLocalizations.of(context)!.blacklist, 
                            quantity: _selectedBlacklists.length
                          ),
                        ]
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            SelectionList(
                              lists: filteringProvider.filtering!.whitelistFilters, 
                              selectedLists: _selectedWhitelists, 
                              onSelect: (list) => handleSelect(list, ListType.whitelist), 
                              selectAll: () => setState(() => _selectedWhitelists = filteringProvider.filtering!.whitelistFilters), 
                              unselectAll: () => setState(() => _selectedWhitelists = [])
                            ),
                            SelectionList(
                              lists: filteringProvider.filtering!.filters, 
                              selectedLists: _selectedBlacklists, 
                              onSelect: (list) => handleSelect(list, ListType.blacklist), 
                              selectAll: () => setState(() => _selectedBlacklists = filteringProvider.filtering!.filters), 
                              unselectAll: () => setState(() => _selectedBlacklists = [])
                            ),
                          ]
                        ),
                      )
                    ],
                  )
                ),
              )
            ],
          ),
        ),
      );
    }
    else {
      return Dialog.fullscreen(
        child: Stack(
          children: [
            DefaultTabController(
              length: 2,
              child: NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder: ((context, innerBoxIsScrolled) {
                  return [
                    SliverOverlapAbsorber(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                      sliver: SliverAppBar(
                        leading: CloseButton(
                          onPressed: () => Navigator.pop(context),
                        ),
                        title: Text(AppLocalizations.of(context)!.selectionMode),
                        pinned: true,
                        floating: true,
                        forceElevated: innerBoxIsScrolled,
                        centerTitle: false,
                        bottom: TabBar(
                          controller: _tabController,
                          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                          tabs: [
                            _Tab(
                              icon: Icons.verified_user_rounded, 
                              text: AppLocalizations.of(context)!.whitelists, 
                              quantity: _selectedWhitelists.length
                            ),
                            _Tab(
                              icon: Icons.gpp_bad_rounded, 
                              text: AppLocalizations.of(context)!.blacklist, 
                              quantity: _selectedBlacklists.length
                            ),
                          ]
                        )
                      ),
                    )
                  ];
                }), 
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    SelectionSliverList(
                      lists: filteringProvider.filtering!.whitelistFilters,
                      selectedLists: _selectedWhitelists,
                      onSelect: (list) => handleSelect(list, ListType.whitelist),
                      selectAll: () => setState(() => _selectedWhitelists = filteringProvider.filtering!.whitelistFilters),
                      unselectAll: () => setState(() => _selectedWhitelists = []),
                    ),
                    SelectionSliverList(
                      lists: filteringProvider.filtering!.filters,
                      selectedLists: _selectedBlacklists,
                      onSelect: (list) => handleSelect(list, ListType.blacklist),
                      selectAll: () => setState(() => _selectedBlacklists = filteringProvider.filtering!.filters),
                      unselectAll: () => setState(() => _selectedBlacklists = []),
                    ),
                  ]
                )
              )
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.ease,
              right: 16,
              bottom: _isScrolled ? -150 : 16,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    onPressed: somethingSelected == true
                      ? () => enableDisableSelected()
                      : null,
                    tooltip: AppLocalizations.of(context)!.enableDisableSelected,
                    child: Icon(
                      Icons.shield_rounded,
                      color: somethingSelected == true
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton.small(
                    onPressed: somethingSelected == true
                      ? () => deleteSelected()
                      : null,
                    tooltip: AppLocalizations.of(context)!.deleteSelected,
                    child: Icon(
                      Icons.delete_rounded,
                      color: somethingSelected == true
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      );
    }
  }
}

class _Tab extends StatelessWidget {
  final IconData icon;
  final String text;
  final int quantity;

  const _Tab({
    Key? key,
    required this.icon,
    required this.text,
    required this.quantity
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(text),
          const SizedBox(width: 8),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Theme.of(context).colorScheme.primaryContainer
            ),
            child: Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onPrimaryContainer
              ),
            ),
          )
        ],
      ),
    );
  }
}