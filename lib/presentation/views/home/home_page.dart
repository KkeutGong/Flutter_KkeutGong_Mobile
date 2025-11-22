import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kkeutgong_mobile/presentation/viewmodels/home_viewmodel.dart';
import 'package:kkeutgong_mobile/shared/styles/colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final HomeViewModel viewModel = Get.put(HomeViewModel());
    
    return Scaffold(
      backgroundColor: colors.gray50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '카운터',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colors.gray900,
              ),
            ),
            const SizedBox(height: 40),
            Obx(() => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 20,
              ),
              decoration: BoxDecoration(
                color: colors.primaryNormal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.primaryNormal.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Text(
                '${viewModel.counter.value}',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: colors.primaryNormal,
                ),
              ),
            )),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.remove,
                  onPressed: viewModel.decrement,
                  colors: colors,
                ),
                const SizedBox(width: 20),
                _buildActionButton(
                  context,
                  icon: Icons.refresh,
                  onPressed: viewModel.reset,
                  colors: colors,
                  isPrimary: false,
                ),
                const SizedBox(width: 20),
                _buildActionButton(
                  context,
                  icon: Icons.add,
                  onPressed: viewModel.increment,
                  colors: colors,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    required ThemeColors colors,
    bool isPrimary = true,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? colors.primaryNormal : colors.gray300,
        foregroundColor: isPrimary ? Colors.white : colors.gray700,
        padding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
      ),
      child: Icon(icon, size: 32),
    );
  }
}
