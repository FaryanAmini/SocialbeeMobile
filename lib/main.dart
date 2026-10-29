import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/builds_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/home_screen.dart';
import 'screens/schedule_screen.dart';
import 'theme.dart';
import 'widgets/glass.dart';
import 'widgets/pieces.dart';

void main() {
  runApp(const SociaBeeApp());
}

class SociaBeeApp extends StatefulWidget {
  const SociaBeeApp({super.key});

  @override
  State<SociaBeeApp> createState() => _SociaBeeAppState();
}

class _SociaBeeAppState extends State<SociaBeeApp> {
  // One AppState for the whole app. Created a single time, here.
  final AppState appState = AppState();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: appState,
      child: MaterialApp(
        title: 'SociaBee',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const AppShell(),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Which dock tab is open: 0 Home, 1 Friends, 2 Calendar, 3 Builds.
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    // All four pages stay in memory; IndexedStack shows just the one we need.
    List<Widget> pages = <Widget>[
      HomeScreen(
        onOpenBuilds: () {
          setState(() => selectedTab = 3);
        },
      ),
      const FriendsScreen(),
      const CalendarScreen(),
      const BuildsScreen(),
    ];

    return Scaffold(
      // extendBody lets page content scroll UNDER the floating dock —
      // that is what makes the dock look like it floats on glass.
      extendBody: true,
      // On a wide window (like a desktop browser) the phone layout is capped
      // and centred instead of stretched. On a real phone this does nothing.
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              IndexedStack(index: selectedTab, children: pages),
              Positioned(
                left: 16,
                right: 16,
                bottom: 10,
                child: GlassDock(
                  selectedTab: selectedTab,
                  onChanged: (int i) => setState(() => selectedTab = i),
                ),
              ),
              // The one create-button in the app: works from any tab.
              Positioned(
                right: 24,
                bottom: 86,
                child: const DockActionButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// The amber circle above the dock. One tap opens scheduling.
class DockActionButton extends StatelessWidget {
  const DockActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return CircleIconButton(
      icon: Icons.add_rounded,
      size: 52,
      emphasis: true,
      onPressed: () => openScheduleScreen(context),
    );
  }
}

class GlassDock extends StatelessWidget {
  const GlassDock({
    super.key,
    required this.selectedTab,
    required this.onChanged,
  });

  final int selectedTab;
  final ValueChanged<int> onChanged;

  // (icon, label) pairs, in dock order.
  static const List<IconData> icons = <IconData>[
    Icons.home_rounded,
    Icons.groups_rounded,
    Icons.calendar_month_rounded,
    Icons.view_in_ar_rounded,
  ];
  static const List<String> labels = <String>[
    'Home',
    'Friends',
    'Calendar',
    'Builds',
  ];

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.all(6),
      frosted: true,
      child: Stack(
        children: <Widget>[
          // The bright capsule that slides to the selected tab.
          AnimatedAlign(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            // -1 is fully left, +1 fully right.
            alignment: Alignment(selectedTab / (icons.length - 1) * 2 - 1, 0),
            child: FractionallySizedBox(
              widthFactor: 1 / icons.length,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withAlpha(40)),
                ),
              ),
            ),
          ),
          // The four tab buttons on top of the capsule.
          Row(
            children: <Widget>[
              for (int i = 0; i < icons.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(i),
                    child: SizedBox(
                      height: 46,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            icons[i],
                            size: 21,
                            color: i == selectedTab
                                ? AppColors.ink
                                : AppColors.inkSoft,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: i == selectedTab
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: i == selectedTab
                                  ? AppColors.ink
                                  : AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// Standard page: big title top-left, optional one-line subtitle, optional
// buttons top-right, then the page content below.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const <Widget>[],
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 6),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: Texts.bigTitle),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: Texts.meta),
                      ],
                    ],
                  ),
                ),
                ...actions,
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

// How much bottom padding every list needs so its last card can scroll
// fully clear of the floating dock. If the dock height changes, change this.
const double listBottomPadding = 152;
