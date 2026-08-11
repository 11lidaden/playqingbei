import 'package:dio/dio.dart';
import '../config/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  late final Dio _dio;

  /// 获取关卡题目
  Future<List<dynamic>> getQuestions(String grade, String subject, int level) async {
    final resp = await _dio.get('/questions', queryParameters: {
      'grade': grade,
      'subject': subject,
      'level': level,
    });
    return resp.data as List<dynamic>;
  }

  /// 获取关卡配置
  Future<List<dynamic>> getLevels(String grade, String subject) async {
    final resp = await _dio.get('/levels', queryParameters: {
      'grade': grade,
      'subject': subject,
    });
    return resp.data as List<dynamic>;
  }

  /// 提交答案
  Future<Map<String, dynamic>> submitAnswers(
    String grade, String subject, int level, List<Map<String, dynamic>> answers,
  ) async {
    final resp = await _dio.post('/submit',
      queryParameters: {'grade': grade, 'subject': subject, 'level': level},
      data: answers,
    );
    return resp.data as Map<String, dynamic>;
  }
}
