import 'package:flutter_dotenv/flutter_dotenv.dart';

String get baseUrl {
  final ip = dotenv.env['IP_ADDRESS'] ?? 'localhost';
  return 'http://$ip:8000';
}
