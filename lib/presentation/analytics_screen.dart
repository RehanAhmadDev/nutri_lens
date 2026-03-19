import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_colors.dart';
import 'providers/weekly_analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(weeklyAnalyticsProvider);

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
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: analyticsState.when(
        loading: () => const Center(
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

    // 🎯 User ka Daily Goal nikalna (Default 2000)
    final user = Supabase.instance.client.auth.currentUser;
    final int dailyGoal = user?.userMetadata?['daily_goal'] ?? 2000;

    for (int i = 0; i < days.length; i++) {
      final double consumed = data[days[i]] ?? 0;

      // 📈 Percentage Calculation
      final int percentage = ((consumed / dailyGoal) * 100).round();

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: consumed,
              color: AppColors.primary,
              width: 22,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: dailyGoal.toDouble(), // Goal tak shadow dikhana
                color: AppColors.textLight.withOpacity(0.1),
              ),
            ),
          ],
          // 🚀 NAYA: Har bar ke upar percentage dikhane ke liye indicator
          showingTooltipIndicators: consumed > 0 ? [0] : [],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
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
          const SizedBox(height: 8),
          Text(
            "Your target is $dailyGoal Kcal/day",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 60), // Space for top percentages
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: dailyGoal * 1.2, // Graph thoda goal se upar tak jaye
                barGroups: barGroups,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),

                // 🚀 NAYA: Tooltip Configuration (Percentage styling)
                barTouchData: BarTouchData(
                  enabled: false, // Touch ki zaroorat nahi, hamesha dikhao
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.transparent, // Background transparent
                    tooltipPadding: EdgeInsets.zero,
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final int perc = ((rod.toY / dailyGoal) * 100).round();
                      return BarTooltipItem(
                        "$perc%",
                        GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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
                      reservedSize: 44,
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
                              fontSize: 12,
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}