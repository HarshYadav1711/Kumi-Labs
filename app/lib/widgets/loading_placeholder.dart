import 'package:flutter/material.dart';

/// Minimal full-screen loading indicator for API-driven screens.
/// Use while fetching data; remove immediately on success or error.
Widget loadingPlaceholder() => const Center(child: CircularProgressIndicator());
