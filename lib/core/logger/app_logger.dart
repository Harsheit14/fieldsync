import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogger {
	AppLogger._();

	static final Logger _logger = Logger(
		printer: kReleaseMode
				? SimplePrinter(printTime: false, colors: false)
				: PrettyPrinter(),
	);

	static void debug(
		Object? message, {
		Object? error,
		StackTrace? stackTrace,
	}) {
		_logger.d(message, error: error, stackTrace: stackTrace);
	}

	static void info(
		Object? message, {
		Object? error,
		StackTrace? stackTrace,
	}) {
		_logger.i(message, error: error, stackTrace: stackTrace);
	}

	static void warning(
		Object? message, {
		Object? error,
		StackTrace? stackTrace,
	}) {
		_logger.w(message, error: error, stackTrace: stackTrace);
	}

	static void error(
		Object? message, {
		Object? error,
		StackTrace? stackTrace,
	}) {
		_logger.e(message, error: error, stackTrace: stackTrace);
	}
}
