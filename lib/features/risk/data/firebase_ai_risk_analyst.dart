import 'package:dio/dio.dart';

import '../domain/risk_analysis.dart';
import '../domain/risk_analyst.dart';
import '../domain/risk_result.dart';

class FirebaseAiRiskAnalyst implements RiskAnalyst {
  static const String _workerUrl = String.fromEnvironment(
    'AI_PROXY_URL',
  );

  final Dio _dio;

  FirebaseAiRiskAnalyst({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<RiskAnalysis> analyze(RiskResult riskResult) async {
    try {
      final response = await _dio.post(
        _workerUrl,
        data: {'riskResult': riskResult.toJson()},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          responseType: ResponseType.json,
          validateStatus: (_) => true,
        ),
      );

      final data = response.data;

      if (response.statusCode != 200) {
        throw Exception('AI proxy returned ${response.statusCode}: $data');
      }

      if (data is! Map<String, dynamic>) {
        throw const FormatException('AI proxy returned an invalid response.');
      }

      if (data['error'] != null) {
        throw Exception('AI proxy error: ${data['error']}');
      }

      return RiskAnalysis.fromJson(
        data,
        riskId: riskResult.id,
        generatedAt: DateTime.now(),
      );
    } on DioException catch (error) {
      throw Exception('AI request failed: ${error.message}');
    }
  }
}
