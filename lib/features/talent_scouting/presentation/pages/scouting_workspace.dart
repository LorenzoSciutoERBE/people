import 'package:flutter/material.dart';

import '../widgets/filters_sidebar.dart';
import '../widgets/results_area.dart';

class ScoutingWorkspace extends StatelessWidget {
  const ScoutingWorkspace({super.key});

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(flex: 3, child: FiltersSidebar()),
      VerticalDivider(width: 1, thickness: 1),
      Expanded(flex: 7, child: ResultsArea()),
    ],
  );
}
