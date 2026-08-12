class AppConstants {
  // 后端API地址（部署后改为服务器IP）
  static const String baseUrl = 'http://106.54.235.209/api';

  // 年级段
  static const Map<String, String> grades = {
    'kindergarten': '🐣 幼儿园',
    'grade-1-2': '🌱 1-2年级',
    'grade-3-4': '🌿 3-4年级',
    'grade-5-6': '🌳 5-6年级',
  };

  // 科目
  static const Map<String, String> subjects = {
    'chinese': '📖 语文',
    'math': '🔢 数学',
    'english': '🔤 英语',
  };

  // 科目颜色
  static const Map<String, int> subjectColors = {
    'chinese': 0xFFFF6B6B,   // 红色
    'math': 0xFF4ECDC4,      // 青色
    'english': 0xFFFFE66D,   // 黄色
  };

  // 角色列表
  static const List<Map<String, String>> characters = [
    {'id': 'cat', 'name': '小猫咪', 'emoji': '🐱'},
    {'id': 'dog', 'name': '小狗狗', 'emoji': '🐶'},
    {'id': 'bear', 'name': '小熊', 'emoji': '🐻'},
  ];
}
