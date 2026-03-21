import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import 'providers/weekly_analytics_provider.dart';
import 'providers/water_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(weeklyAnalyticsProvider);
    final waterState = ref.watch(waterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Weekly Progress',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark, // 🚀 const hataya
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textDark), // 🚀 const hataya
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 📊 1. CALORIES CHART SECTION
            SizedBox(
              height: 420,
              child: analyticsState.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: AppColors.primary), // 🚀 const hataya
                ),
                error: (err, stack) => Center(
                  child: Text(
                    "Error: $err",
                    style: GoogleFonts.poppins(color: AppColors.error), // 🚀 const hataya
                  ),
                ),
                data: (data) {
                  if (data.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildChart(data);
                },
              ),
            ),

            // 💧 2. WATER HISTORY SECTION
            _buildWaterHistorySection(waterState),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 80,
            color: AppColors.textLight.withOpacity(0.3), // 🚀 const hataya
          ),
          const SizedBox(height: 16),
          Text(
            "No data for this week yet!",
            style: GoogleFonts.poppins(
              color: AppColors.textLight, // 🚀 const hataya
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(Map<String, double> data) {
    final List<BarChartGroupData> barGroups = [];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final user = Supabase.instance.client.auth.currentUser;
    final int dailyGoal = user?.userMetadata?['daily_goal'] ?? 2000;

    int index = 0;
    for (String day in days) {
      final double consumed = data[day] ?? 0.0;

      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: consumed,
              // 🎨 PREMIUM TOUCH: Gradient use kiya bar ke liye!
              gradient: LinearGradient(
                colors: [AppColors.secondary, AppColors.primary],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 22,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: dailyGoal.toDouble(),
                color: AppColors.textLight.withOpacity(0.08), // 🚀 const hataya
              ),
            ),
          ],
          showingTooltipIndicators: consumed > 0 ? [0] : [],
        ),
      );
      index++;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.textDark.withOpacity(0.03),
                blurRadius: 24,
                offset: const Offset(0, 8),
              )
            ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Calories Consumption",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark, // 🚀 const hataya
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Your target is $dailyGoal Kcal/day",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textLight, // 🚀 const hataya
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: dailyGoal * 1.2,
                  barGroups: barGroups,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),

                  barTouchData: BarTouchData(
                    enabled: false,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.transparent,
                      tooltipPadding: EdgeInsets.zero,
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final int perc = ((rod.toY / dailyGoal) * 100).round();
                        return BarTooltipItem(
                          "$perc%",
                          GoogleFonts.poppins(
                            color: AppColors.primary, // 🚀 const hataya
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),

                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() >= days.length || value.toInt() < 0) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(
                              days[value.toInt()],
                              style: GoogleFonts.poppins(
                                color: AppColors.textLight, // 🚀 const hataya
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 💧 🚀 THEME AWARE WATER HISTORY
  Widget _buildWaterHistorySection(WaterState waterState) {
    final List<DateTime> last7Days = List.generate(7, (index) => DateTime.now().subtract(Duration(days: index))).reversed.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_rounded, color: AppColors.primary, size: 26), // 🚀 Theme awre
              const SizedBox(width: 8),
              Text(
                "Water Intake History",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 🎨 Theme Aware Container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05), // Theme ke hisab se tint
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.primary.withOpacity(0.15), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5)
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: last7Days.map((date) {
                final String dateString = date.toString().split(' ')[0];
                final int glasses = waterState.waterHistory[dateString] ?? 0;
                final String dayName = DateFormat('EEE').format(date);
                final bool reachedGoal = glasses >= waterState.dailyGoal;

                return Column(
                  children: [
                    Text(
                      glasses.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: reachedGoal ? AppColors.primary : AppColors.textLight.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Icon(
                      reachedGoal ? Icons.verified_rounded : Icons.water_drop_outlined,
                      size: 20,
                      color: reachedGoal ? AppColors.primary : AppColors.textLight.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dayName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: reachedGoal ? AppColors.primary.withOpacity(0.8) : AppColors.textLight.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}