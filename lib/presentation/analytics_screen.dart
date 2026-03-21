import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // 🚀 NAYA: Dates ko format karne ke liye
import '../utils/app_colors.dart';
import 'providers/weekly_analytics_provider.dart';
import 'providers/water_provider.dart'; // 💧 NAYA: Water provider import kiya

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(weeklyAnalyticsProvider);
    final waterState = ref.watch(waterProvider); // 💧 NAYA: Water state ko watch karein

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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 📊 1. CALORIES CHART SECTION
            SizedBox(
              height: 400, // Chart ko ek fixed height de di taake UI kharab na ho
              child: analyticsState.when(
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

    // 🎯 User ka Daily Goal nikalna (Default 2000)
    final user = Supabase.instance.client.auth.currentUser;
    final int dailyGoal = user?.userMetadata?['daily_goal'] ?? 2000;

    // Loop logic to process the data for the chart...
    // Note: The logic inside your loop seems to assume `data` maps keys 'Mon', 'Tue', etc.
    // If your backend gives you actual dates, you might need to map them properly.
    // But assuming it matches your UI logic perfectly, we keep it as is.

    int index = 0;
    for (String day in days) {
      final double consumed = data[day] ?? 0.0;

      barGroups.add(
        BarChartGroupData(
          x: index,
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
          showingTooltipIndicators: consumed > 0 ? [0] : [],
        ),
      );
      index++;
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

                // Tooltip Configuration (Percentage styling)
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
        ],
      ),
    );
  }

  // 💧 🚀 NAYA: Water History UI Builder
  Widget _buildWaterHistorySection(WaterState waterState) {
    // Pichle 7 din nikalna
    final List<DateTime> last7Days = List.generate(7, (index) => DateTime.now().subtract(Duration(days: index))).reversed.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop_rounded, color: Color(0xFF3182CE), size: 24),
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

          // Khoobsurat Container jismein 7 din ki row hogi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF8FF), // Light Blue
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF90CDF4), width: 1.5),
              boxShadow: [BoxShadow(color: const Color(0xFF4299E1).withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: last7Days.map((date) {
                // Date format kar ke check karein map mein hai ya nahi
                final String dateString = date.toString().split(' ')[0];
                final int glasses = waterState.waterHistory[dateString] ?? 0;

                // Din ka naam (e.g., "Mon", "Tue")
                final String dayName = DateFormat('EEE').format(date);

                // Goal poora kiya hai ya nahi?
                final bool reachedGoal = glasses >= waterState.dailyGoal;

                return Column(
                  children: [
                    Text(
                      glasses.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: reachedGoal ? const Color(0xFF2B6CB0) : const Color(0xFF4299E1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Chota sa icon indicator
                    Icon(
                      reachedGoal ? Icons.verified_rounded : Icons.water_drop_outlined,
                      size: 20,
                      color: reachedGoal ? const Color(0xFF3182CE) : const Color(0xFF90CDF4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dayName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF2B6CB0).withOpacity(0.7),
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