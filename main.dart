import 'package:flutter/material.dart';
import 'screens/digital_twin_screen.dart'; 
import 'screens/analytics_screen.dart';
import 'screens/machine_health_screen.dart';
import 'screens/engineering_screen.dart';
import 'screens/about_aura_screen.dart';
import 'services/aura_data_service.dart';
import 'models/aura_live_data.dart';
import 'widgets/smoothed_series_builder.dart';

void main() {
  runApp(const AuraApp());
}

// ============================================================
// AURA APP
// ============================================================

class AuraApp extends StatelessWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AURA OS',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0D0C),
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D26A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AuraHome(),
    );
  }
}

// ============================================================
// COLORS
// ============================================================

class AuraColors {
  static const background = Color(0xFF0B0D0C);
  static const surface = Color(0xFF121615);
  static const surface2 = Color(0xFF171C1A);
  static const emerald = Color(0xFF00D26A);
  static const emeraldDark = Color(0xFF0C3D28);
  static const emeraldSoft = Color(0xFF123A28);
  static const white = Color(0xFFF4F7F5);
  static const muted = Color(0xFF8C9691);
  static const muted2 = Color(0xFF5E6763);
  static const warning = Color(0xFFFFB83D);
}

// ============================================================
// MAIN NAVIGATION
// ============================================================

class AuraHome extends StatefulWidget {
  const AuraHome({super.key});

  @override
  State<AuraHome> createState() => _AuraHomeState();
}

class _AuraHomeState extends State<AuraHome> {
  int selectedIndex = 0;

  final List<Widget> pages =  [
    DashboardScreen(),
    DigitalTwinScreen(),
    AnalyticsScreen(),
    MachineHealthScreen(),
    EngineeringScreen(),
    AboutAuraScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.background,
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        height: 70,
        backgroundColor: const Color(0xFF111514),
        indicatorColor: AuraColors.emeraldDark,
        selectedIndex: selectedIndex,
        labelBehavior:
            NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_in_ar_outlined),
            selectedIcon: Icon(Icons.view_in_ar),
            label: 'Twin',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.health_and_safety_outlined),
            selectedIcon: Icon(Icons.health_and_safety),
            label: 'Health',
          ),
          NavigationDestination(
            icon: Icon(Icons.engineering_outlined),
            selectedIcon: Icon(Icons.engineering),
            label: 'Engineering',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'About',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  final AuraDataService _dataService = AuraDataService.instance;
  int selectedRange = 7;

  @override
  void initState() {
    super.initState();

    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _dataService,
      builder: (context, child) {
        final data = _dataService.currentData;
        final history = _dataService.getHistoryForRange(
          _durationForRange(selectedRange),
        );
        final pm25History = [
          for (final reading in history) reading.inletPm25,
        ];
        final pm10History = [
          for (final reading in history) reading.inletPm10,
        ];

        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 720;

              return AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        14,
                        compact ? 10 : 14,
                        14,
                        10,
                      ),
                      child: Column(
                        children: [
                          _DashboardHeader(
                            pulse: _animation.value,
                          ),
                          const SizedBox(height: 12),
                          _SystemHealthHero(
                           pulse: _animation.value,
                           data: data, 
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _SmallMetricCard(
                                  title: 'UPTIME',
                                  value: '12d 04h',
                                  subtitle: 'CONTINUOUS',
                                  icon: Icons.timer_outlined,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _SmallMetricCard(
                                  title: 'EFFICIENCY',
                                  value: '${data.filterEfficiency.toStringAsFixed(1)}%',
                                  subtitle: 'SYSTEM OUTPUT',
                                  icon: Icons.speed_outlined,
                                  green: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _SectionTitle(
                                  title: 'AIR QUALITY',
                                  action: data.esp32Online ? 'LIVE · ESP32' : 'OFFLINE',
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              Expanded(
                                child: _AirQualityCard(
                                  title: 'PM2.5',
                                  before: data.inletPm25.toStringAsFixed(1),
                                  after: data.outletPm25.toStringAsFixed(1),
                                  unit: 'µg/m³',
                                  reduction:
                                      '${data.pm25RemovalPercent.toStringAsFixed(0)}%',
                                  values: pm25History,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _AirQualityCard(
                                  title: 'PM10',
                                  before: data.inletPm10.toStringAsFixed(1),
                                  after: data.outletPm10.toStringAsFixed(1),
                                  unit: 'µg/m³',
                                  reduction:
                                      '${data.pm10RemovalPercent.toStringAsFixed(0)}%',
                                  values: pm10History,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _dashboardRangeSelector(),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _SensorCard(
                                  title: 'CO₂',
                                  value: data.co2Ppm.toStringAsFixed(0),
                                  unit: 'PPM',
                                  icon: Icons.cloud_outlined,
                                  status: 'OPTIMAL',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _SensorCard(
                                  title: 'pH LEVEL',
                                  value: data.ph.toStringAsFixed(1),
                                  unit: 'pH',
                                  icon: Icons.water_drop_outlined,
                                  status: 'STABLE',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const _SectionTitle(
                            title: 'ENVIRONMENT',
                            action: 'SENSORS',
                          ),
                          const SizedBox(height: 7),
                          _EnvironmentStrip(
                            data: data,
                          ),
                          const SizedBox(height: 10),
                          _SystemFooter(
                            data: data,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Duration _durationForRange(int range) {
    if (range == 1) {
      return const Duration(hours: 24);
    }

    if (range == 7) {
      return const Duration(days: 7);
    }

    return const Duration(days: 30);
  }

  Widget _dashboardRangeSelector() {
    return Row(
      children: [
        _dashboardRangeButton('24H', 1),
        const SizedBox(width: 6),
        _dashboardRangeButton('7D', 7),
        const SizedBox(width: 6),
        _dashboardRangeButton('30D', 30),
        const Spacer(),
        const Icon(
          Icons.swipe_outlined,
          size: 13,
          color: Color(0xFF56605B),
        ),
      ],
    );
  }

  Widget _dashboardRangeButton(String text, int value) {
    final selected = selectedRange == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRange = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AuraColors.emerald.withValues(alpha: 0.09)
              : AuraColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AuraColors.emerald.withValues(alpha: 0.31)
                : const Color(0xFF252E2A),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected
                ? AuraColors.emerald
                : AuraColors.muted2,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DASHBOARD HEADER
// ============================================================

class _DashboardHeader extends StatelessWidget {
  final double pulse;

  const _DashboardHeader({
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final glow = 0.25 + pulse * 0.25;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AuraColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: const Icon(
            Icons.menu_rounded,
            color: AuraColors.muted,
            size: 21,
          ),
        ),

        const SizedBox(width: 11),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AURA OS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: AuraColors.white,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'CLEAN-AIR BIO SYSTEM',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                  color: AuraColors.muted,
                ),
              ),
            ],
          ),
        ),

        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AuraColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AuraColors.emerald.withValues(
                alpha: 0.15 + glow,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AuraColors.emerald.withValues(
                  alpha: glow * 0.35,
                ),
                blurRadius: 14,
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: AuraColors.white,
            size: 20,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SYSTEM HEALTH HERO
// ============================================================

class _SystemHealthHero extends StatelessWidget {
  final double pulse;
  final AuraLiveData data;

  const _SystemHealthHero({
    required this.pulse,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final glow = 10 + pulse * 12;

    final health = data.systemHealth;

    final healthLabel = health >= 90
        ? 'HEALTHY'
        : health >= 70
            ? 'WARNING'
            : 'CRITICAL';

    final healthMessage = health >= 90
        ? 'ALL SYSTEMS NOMINAL'
        : health >= 70
            ? 'SYSTEM ATTENTION REQUIRED'
            : 'SYSTEM FAULT DETECTED';

    final statusColor = health >= 90
        ? AuraColors.emerald
        : health >= 70
            ? const Color(0xFFFFB020)
            : const Color(0xFFFF4D4D);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 17,
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: AuraColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(
            alpha: 0.12 + pulse * 0.12,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(
              alpha: 0.08 + pulse * 0.07,
            ),
            blurRadius: glow,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'SYSTEM STATUS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
              color: AuraColors.muted,
            ),
          ),

          const SizedBox(height: 9),

          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  statusColor,
                  statusColor.withValues(alpha: 0.65),
                  statusColor,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(
                    alpha: 0.18 + pulse * 0.16,
                  ),
                  blurRadius: 24 + pulse * 12,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AuraColors.background,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    health >= 70
                        ? Icons.check_rounded
                        : Icons.warning_amber_rounded,
                    color: statusColor,
                    size: 27,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    healthLabel,
                    style: const TextStyle(
                      color: AuraColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            healthMessage,
            style: TextStyle(
              color: statusColor,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            data.esp32Online
                ? 'AURA BIO-AIR PROCESSING ACTIVE'
                : 'ESP32 OFFLINE · AWAITING CONNECTION',
            style: const TextStyle(
              color: AuraColors.muted2,
              fontSize: 8,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// SMALL METRIC CARD
// ============================================================

class _SmallMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool green;

  const _SmallMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.green = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AuraColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: green
                  ? AuraColors.emeraldDark
                  : AuraColors.surface2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: green
                  ? AuraColors.emerald
                  : AuraColors.muted,
              size: 18,
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AuraColors.muted,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AuraColors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: green
                        ? AuraColors.emerald
                        : AuraColors.muted2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final String action;

  const _SectionTitle({
    required this.title,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AuraColors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: AuraColors.emeraldDark,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            action,
            style: const TextStyle(
              color: AuraColors.emerald,
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// AIR QUALITY CARD
// ============================================================

class _AirQualityCard extends StatelessWidget {
  final String title;
  final String before;
  final String after;
  final String unit;
  final String reduction;
  final List<double> values;

  const _AirQualityCard({
    required this.title,
    required this.before,
    required this.after,
    required this.unit,
    required this.reduction,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 142,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AuraColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AuraColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AuraColors.emeraldDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '-$reduction',
                  style: const TextStyle(
                    color: AuraColors.emerald,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                before,
                style: const TextStyle(
                  color: AuraColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: AuraColors.emerald,
                  size: 14,
                ),
              ),
              Text(
                after,
                style: const TextStyle(
                  color: AuraColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: const TextStyle(
                    color: AuraColors.muted,
                    fontSize: 7,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          SizedBox(
            height: 36,
            width: double.infinity,
            child: SmoothedSeriesBuilder(
              values: values,
              builder: (context, series) {
                return CustomPaint(
                  painter: _MiniGraphPainter(
                    values: series,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MINI GRAPH
// ============================================================

class _MiniGraphPainter extends CustomPainter {
  final List<double> values;

  const _MiniGraphPainter({
    required this.values,
  });

 @override
void paint(Canvas canvas, Size size) {
  if (values.isEmpty ||
      size.width <= 0 ||
      size.height <= 0) {
    return;
  }

  final glowPaint = Paint()
    ..color = AuraColors.emerald.withValues(alpha: 0.22)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.round;

  final linePaint = Paint()
    ..color = AuraColors.emerald
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.7
    ..strokeCap = StrokeCap.round;

  final pointPaint = Paint()
    ..color = AuraColors.emerald
    ..style = PaintingStyle.fill;

  // Calculate the visible range.
  final min = values.reduce(
    (a, b) => a < b ? a : b,
  );

  final max = values.reduce(
    (a, b) => a > b ? a : b,
  );

  final range = (max - min).abs() < 0.001
      ? 1.0
      : max - min;

  // Keep the same vertical area used by the existing graph.
  const topPadding = 0.10;
  const graphHeight = 0.78;

  // ─────────────────────────────────────────────
  // GRID
  // ─────────────────────────────────────────────

  final gridPaint = Paint()
    ..color = AuraColors.emerald.withValues(alpha: 0.10)
    ..strokeWidth = 0.7;

  for (int i = 0; i <= 3; i++) {
    final fraction = i / 3;
    final y = size.height -
        (fraction * (size.height * graphHeight)) -
        size.height * topPadding;

    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      gridPaint,
    );
  }

  // ─────────────────────────────────────────────
  // GRAPH LINE
  // ─────────────────────────────────────────────

  final path = Path();

  for (int i = 0; i < values.length; i++) {
    final x = values.length == 1
        ? size.width
        : i / (values.length - 1) * size.width;

    final y = size.height -
        (((values[i] - min) / range) *
            (size.height * graphHeight)) -
        size.height * topPadding;

    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }

  canvas.drawPath(path, glowPaint);
  canvas.drawPath(path, linePaint);

  // ─────────────────────────────────────────────
  // LATEST VALUE INDICATOR
  // ─────────────────────────────────────────────

  final latest = values.last;

  final latestY = size.height -
      (((latest - min) / range) *
          (size.height * graphHeight)) -
      size.height * topPadding;

  // Latest-point glow.
  final latestGlowPaint = Paint()
    ..color = AuraColors.emerald.withValues(alpha: 0.30)
    ..style = PaintingStyle.fill;

  canvas.drawCircle(
    Offset(size.width - 2, latestY),
    4.0,
    latestGlowPaint,
  );

  // Latest-point center.
  canvas.drawCircle(
    Offset(size.width - 2, latestY),
    2.2,
    pointPaint,
  );

  // Latest numeric value.
  final latestText = TextPainter(
    text: TextSpan(
      text: latest.toStringAsFixed(1),
      style: TextStyle(
        color: AuraColors.emerald,
        fontSize: 8,
        fontWeight: FontWeight.w700,
      ),
    ),
    textDirection: TextDirection.ltr,
  );

  latestText.layout();

  // Keep the label inside the graph bounds.
  final textX = (size.width - latestText.width - 5)
      .clamp(0.0, size.width - latestText.width);

  final textY = (latestY - latestText.height - 1)
      .clamp(0.0, size.height - latestText.height);

  latestText.paint(
    canvas,
    Offset(textX, textY),
  );
}

  @override
  bool shouldRepaint(
    covariant _MiniGraphPainter oldDelegate,
  ) {
    if (oldDelegate.values.length != values.length) {
      return true;
    }

    for (int i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) {
        return true;
      }
    }

    return false;
  }
}

// ============================================================
// SENSOR CARD
// ============================================================

class _SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String status;
  final IconData icon;

  const _SensorCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.status,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 105,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AuraColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AuraColors.emerald,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AuraColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),

          const Spacer(),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AuraColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: const TextStyle(
                    color: AuraColors.muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 3),

          Text(
            status,
            style: const TextStyle(
              color: AuraColors.emerald,
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ENVIRONMENT STRIP
// ============================================================

class _EnvironmentStrip extends StatelessWidget {
  const _EnvironmentStrip({
    required this.data,
  });

  final AuraLiveData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 11,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: AuraColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _EnvironmentMetric(
              title: 'TEMP',
              value: '${data.airTemperature.toStringAsFixed(1)}°C',
              icon: Icons.thermostat_outlined,
            ),
          ),
          Expanded(
            child: _EnvironmentMetric(
              title: 'HUMIDITY',
              value: '${data.humidity.toStringAsFixed(0)}%',
              icon: Icons.water_drop_outlined,
            ),
          ),
          Expanded(
            child: _EnvironmentMetric(
              title: 'AIRFLOW',
              value: '${data.airflow.toStringAsFixed(1)} m/s',
              icon: Icons.air,
            ),
          ),
          Expanded(
            child: _EnvironmentMetric(
              title: 'AIR INDEX',
              value: data.systemHealth >= 90
                  ? 'GOOD'
                  : data.systemHealth >= 70
                      ? 'WARN'
                      : 'CRITICAL',
              icon: Icons.shield_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
  
class _EnvironmentMetric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool green;

  const _EnvironmentMetric({
    required this.title,
    required this.value,
    required this.icon,
  }) : green = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 15,
          color: green
              ? AuraColors.emerald
              : AuraColors.muted,
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(
            color: AuraColors.muted2,
            fontSize: 6.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: green
                  ? AuraColors.emerald
                  : AuraColors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 35,
      color: Colors.white.withValues(alpha: 0.07),
    );
  }
}

// ============================================================
// SYSTEM FOOTER
// ============================================================

class _SystemFooter extends StatelessWidget {
  const _SystemFooter({
    required this.data,
  });

  final AuraLiveData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF101311),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AuraColors.emerald.withValues(alpha: 0.09),
        ),
      ),
      child: Row(
        children: [
          _FooterStatus(
            label: 'FILTRATION',
            value: data.filtrationActive ? 'ON' : 'OFF',
          ),
          _FooterStatus(
            label: 'BIOREACTOR',
            value: data.bioreactorActive ? 'ON' : 'OFF',
          ),
          _FooterStatus(
            label: 'WATER SYSTEM',
            value: data.waterSystemActive ? 'ON' : 'OFF',
          ),
          _FooterStatus(
            label: 'EXHAUST FAN',
            value: data.exhaustFanActive ? 'ON' : 'OFF',
          ),
          _FooterStatus(
            label: 'CONTROL',
            value: data.esp32Online ? 'ONLINE' : 'OFFLINE',
          ),
        ],
      ),
    );
  }
}

class _FooterStatus extends StatelessWidget {
  final String label;
  final String value;

  const _FooterStatus({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AuraColors.muted2,
              fontSize: 6.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: AuraColors.emerald,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _FooterDivider extends StatelessWidget {
  const _FooterDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 22,
      color: Colors.white.withValues(alpha: 0.07),
    );
  }
}

