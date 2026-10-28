// turning gray contact into new contact
// opens from friends page
// who are they
// building or maintaining
// how often to be nudged

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/glass.dart';
import '../widgets/pieces.dart';

void openContactSetup(BuildContext context, Friend friend) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          12,
          12,
          12 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: ContactSetupSheet(friend: friend),
      );
    },
  );
}

class ContactSetupSheet extends StatefulWidget {
  const ContactSetupSheet({super.key, required this.friend});

  final Friend friend;

  @override
  State<ContactSetupSheet> createState() => _ContactSetupSheetState();
}

class _ContactSetupSheetState extends State<ContactSetupSheet> {
  // Local copies: edits only reach the real Friend object when the user
  // presses "Done". (TextField state needs a controller — a normal Flutter
  // pattern; the controller holds the text, we read controller.text.)
  late final TextEditingController descriptionController =
      TextEditingController(text: widget.friend.description);
  late Relationship relationship = widget.friend.relationship;
  late int frequencyDays = widget.friend.frequencyDays;

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  void _finish() {
    AppState app = AppScope.of(context);
    // Write the three answers back to the shared Friend object.
    widget.friend.description = descriptionController.text.trim();
    widget.friend.relationship = relationship;
    widget.friend.frequencyDays = frequencyDays;
    app.finishSetup(widget.friend); // flips it from gray to normal
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Center(child: SheetGrabber()),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Avatar(widget.friend, size: 48, solid: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(widget.friend.name, style: Texts.bigTitle),
                      const SizedBox(height: 2),
                      const Text('Set up', style: Texts.meta),
                    ],
                  ),
                ),
              ],
            ),

            const SectionLabel('What comes to mind when you think of them?'),
            TextField(
              controller: descriptionController,
              style: Texts.body,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Roommate. Ramen crawls. Bad movies.',
                hintStyle: const TextStyle(color: AppColors.muted),
                filled: true,
                fillColor: Colors.white.withAlpha(10),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
              ),
            ),

            const SectionLabel('Relationship'),
            Row(
              children: <Widget>[
                Expanded(
                  child: _ChoiceCard(
                    title: 'Building',
                    caption: 'Aim for a 6-month streak',
                    selected: relationship == Relationship.building,
                    color: AppColors.building,
                    onTap: () =>
                        setState(() => relationship = Relationship.building),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ChoiceCard(
                    title: 'Maintaining',
                    caption: 'Keep the friendship alive',
                    selected: relationship == Relationship.maintaining,
                    color: AppColors.maintaining,
                    onTap: () =>
                        setState(() => relationship = Relationship.maintaining),
                  ),
                ),
              ],
            ),

            const SectionLabel('How often?'),
            // Show the current value above the slider.
            Text(
              widget.friend.isSetUp
                  ? widget.friend.frequencyLabel
                  : _frequencyLabelFor(frequencyDays),
              style: Texts.itemTitle,
            ),
            Slider(
              min: 1,
              max: 60,
              value: frequencyDays.toDouble().clamp(1, 60),
              onChanged: (double value) =>
                  setState(() => frequencyDays = value.round()),
            ),

            const SizedBox(height: 12),
            AppButton(
              label: 'Done',
              icon: Icons.check_rounded,
              onPressed: _finish,
            ),
          ],
        ),
      ),
    );
  }

  // Same wording as Friend.frequencyLabel, but reads the local edit value.
  String _frequencyLabelFor(int days) {
    if (days <= 1) return 'Every day';
    if (days == 7) return 'Once a week';
    if (days == 14) return 'Every 2 weeks';
    if (days == 30) return 'Once a month';
    return 'Every $days days';
  }
}

// One of the two big relationship choices.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.caption,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String caption;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected ? color.withAlpha(34) : Colors.white.withAlpha(10),
          border: Border.all(
            color: selected ? color : glassBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                // Expanded: long titles ('Maintaining') wrap instead of
                // pushing the checkmark off the edge.
                Expanded(child: Text(title, style: Texts.itemTitle)),
                if (selected) Icon(Icons.check_rounded, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(caption, style: Texts.meta),
          ],
        ),
      ),
    );
  }
}
