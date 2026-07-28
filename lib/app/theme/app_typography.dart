import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
	AppTypography._();

	static const TextTheme light = TextTheme(
		displayLarge: TextStyle(
			color: AppColors.textPrimary,
			fontSize: 57,
			fontWeight: FontWeight.w400,
			letterSpacing: -0.25,
		),
		displayMedium: TextStyle(
			color: AppColors.textPrimary,
			fontSize: 45,
			fontWeight: FontWeight.w400,
		),
		displaySmall: TextStyle(
			color: AppColors.textPrimary,
			fontSize: 36,
			fontWeight: FontWeight.w400,
		),
		headlineLarge: TextStyle(
			color: AppColors.textPrimary,
			fontSize: 32,
			fontWeight: FontWeight.w600,
		),
		headlineMedium: TextStyle(
			color: AppColors.textPrimary,
			fontSize: 28,
			fontWeight: FontWeight.w600,
		),
		headlineSmall: TextStyle(
			color: AppColors.textPrimary,
			fontSize: 24,
			fontWeight: FontWeight.w600,
		),
		titleLarge: TextStyle(
			color: AppColors.textPrimary,
			fontSize: 22,
			fontWeight: FontWeight.w600,
		),
		titleMedium: TextStyle(
			color: AppColors.textPrimary,
			fontSize: 16,
			fontWeight: FontWeight.w600,
			letterSpacing: 0.15,
		),
		titleSmall: TextStyle(
			color: AppColors.textPrimary,
			fontSize: 14,
			fontWeight: FontWeight.w600,
			letterSpacing: 0.1,
		),
		bodyLarge: TextStyle(
			color: AppColors.textPrimary,
			fontSize: 16,
			fontWeight: FontWeight.w400,
			letterSpacing: 0.5,
		),
		bodyMedium: TextStyle(
			color: AppColors.textPrimary,
			fontSize: 14,
			fontWeight: FontWeight.w400,
			letterSpacing: 0.25,
		),
		bodySmall: TextStyle(
			color: AppColors.textSecondary,
			fontSize: 12,
			fontWeight: FontWeight.w400,
			letterSpacing: 0.4,
		),
		labelLarge: TextStyle(
			color: AppColors.textPrimary,
			fontSize: 14,
			fontWeight: FontWeight.w500,
			letterSpacing: 0.1,
		),
		labelMedium: TextStyle(
			color: AppColors.textPrimary,
			fontSize: 12,
			fontWeight: FontWeight.w500,
			letterSpacing: 0.5,
		),
		labelSmall: TextStyle(
			color: AppColors.textSecondary,
			fontSize: 11,
			fontWeight: FontWeight.w500,
			letterSpacing: 0.5,
		),
	);
}
