import 'dart:collection';

import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;

class Env {
	const Env._(this._values);

	final Map<String, String> _values;

	static Future<Env> load({String fileName = '.env'}) async {
		try {
			await dotenv.dotenv.load(fileName: fileName);
			return Env._(Map<String, String>.unmodifiable(dotenv.dotenv.env));
		} catch (error) {
			throw EnvLoadException(
				'Failed to load environment file "$fileName".',
				cause: error,
			);
		}
	}

	String? string(String key) => _values[key];

	String requireString(String key) {
		final value = string(key);
		if (value == null || value.trim().isEmpty) {
			throw EnvValueException(
				'Missing required environment value for "$key".',
			);
		}
		return value;
	}

	int? integer(String key) {
		final value = string(key);
		if (value == null || value.trim().isEmpty) {
			return null;
		}
		return int.tryParse(value.trim());
	}

	double? decimal(String key) {
		final value = string(key);
		if (value == null || value.trim().isEmpty) {
			return null;
		}
		return double.tryParse(value.trim());
	}

	bool? boolean(String key) {
		final value = string(key);
		if (value == null || value.trim().isEmpty) {
			return null;
		}

		final normalizedValue = value.trim().toLowerCase();
		if (normalizedValue == 'true') {
			return true;
		}
		if (normalizedValue == 'false') {
			return false;
		}
		return null;
	}

	bool contains(String key) => _values.containsKey(key);

	Map<String, String> asMap() => UnmodifiableMapView(_values);
}

class EnvLoadException implements Exception {
	const EnvLoadException(this.message, {this.cause});

	final String message;
	final Object? cause;

	@override
	String toString() => cause == null
			? 'EnvLoadException: $message'
			: 'EnvLoadException: $message (cause: $cause)';
}

class EnvValueException implements Exception {
	const EnvValueException(this.message);

	final String message;

	@override
	String toString() => 'EnvValueException: $message';
}
