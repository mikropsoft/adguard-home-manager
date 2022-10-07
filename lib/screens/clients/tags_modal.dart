import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TagsModal extends StatefulWidget {
  final List<String> selectedTags;
  final List<String> tags;
  final void Function(List<String>) onConfirm;

  const TagsModal({
    Key? key,
    required this.selectedTags,
    required this.tags,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<TagsModal> createState() => _TagsModalState();
}

class _TagsModalState extends State<TagsModal> {
  List<String> selectedTags = [];

  @override
  void initState() {
    selectedTags = widget.selectedTags;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    void checkUncheckTag(bool value, String tag) {
      if (value == true) {
        setState(() {
          selectedTags.add(tag);
        });
      }
      else if (value == false) {
        setState(() {
          selectedTags = selectedTags.where((s) => s != tag).toList();
        });
      }
    }
    return AlertDialog(
      scrollable: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: 20
      ),
      title: Column(
        children: [
          const Icon(Icons.label_rounded),
          const SizedBox(height: 20),
          Text(AppLocalizations.of(context)!.tags)
        ],
      ),
      content: SizedBox(
        width: double.minPositive,
        height: MediaQuery.of(context).size.height*0.5,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.tags.length,
          itemBuilder: (context, index) => CheckboxListTile(
            title: Text(
              widget.tags[index],
              style: const TextStyle(
                fontWeight: FontWeight.normal
              ),
            ),
            value: selectedTags.contains(widget.tags[index]), 
            checkboxShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5)
            ),
            onChanged: (value) => checkUncheckTag(value!, widget.tags[index])
          )
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: Text(AppLocalizations.of(context)!.cancel)
        ),
        TextButton(
          onPressed: selectedTags.isNotEmpty
            ? () {
                widget.onConfirm(selectedTags);
                Navigator.pop(context);
              }
            : null, 
          child: Text(
            AppLocalizations.of(context)!.confirm,
            style: TextStyle(
              color: selectedTags.isNotEmpty
                ? Theme.of(context).primaryColor
                : Colors.grey
            ),
          )
        ),
      ],
    );
  }
}