import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/admin_service.dart';

final adminServiceProvider = Provider((ref) => AdminService());
