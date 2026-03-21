import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutri_lens/presentation/providers/water_provider.dart';
import 'package:nutri_lens/presentation/providers/weekly_analytics_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';

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
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textDark),
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
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (err, stack) => Center(
                  child: Text(
                    "Error: $err",
                    style: GoogleFonts.poppins(color: AppColors.error),
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
            color: AppColors.textLight.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "No data for this week yet!",
            style: GoogleFonts.poppins(
              color: AppColors.textLight,
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
                color: AppColors.textLight.withOpacity(0.08),
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
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Calories Consumption",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Your target is $dailyGoal Kcal/day",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textLight,
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
                            color: AppColors.primary,
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
                                color: AppColors.textLight,
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

  Widget _buildWaterHistorySection(WaterState waterState) {
    // 📅 Aaj ki date nikalna comparison ke liye
    final DateTime now = DateTime.now();
    final String todayFormatted = DateFormat('yyyy-MM-dd').format(now);

    final List<DateTime> last7Days = List.generate(
        7,
            (index) => now.subtract(Duration(days: index))
    ).reversed.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_rounded, color: AppColors.primary, size: 26),
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
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.primary.withOpacity(0.15), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: last7Days.map((date) {
                final String dateString = DateFormat('yyyy-MM-dd').format(date);
                final int glasses = waterState.waterHistory[dateString] ?? 0;
                final String dayName = DateFormat('EEE').format(date);

                // 🚀 Naya Logic:
                final bool isToday = dateString == todayFormatted; // Kya ye aaj ka din hai?
                final bool hasEntry = glasses > 0; // Kya record hai?
                final bool reachedGoal = glasses >= waterState.dailyGoal; // Goal poora?

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                    // Agar aaj ka din hai toh highlighter dikhayenge
                    color: isToday ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: isToday
                        ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        glasses.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          // Entry hai toh dark, warna light
                          color: hasEntry ? AppColors.textDark : AppColors.textLight.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Icon(
                        reachedGoal ? Icons.verified_rounded : (hasEntry ? Icons.water_drop_rounded : Icons.water_drop_outlined),
                        size: 20,
                        color: hasEntry ? AppColors.primary : AppColors.primary.withOpacity(0.2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dayName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isToday
                              ? AppColors.primary
                              : (hasEntry ? AppColors.textDark.withOpacity(0.8) : AppColors.textLight.withOpacity(0.5)),
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      if (isToday) // Aaj ke din ke neeche chota sa dot
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          height: 4,
                          width: 4,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        )
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}