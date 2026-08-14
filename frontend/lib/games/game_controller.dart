/// 游戏通用接口：跑酷/射击等游戏共用 HUD 与过关/失败浮层
abstract class GameController {
  /// 已收集金币数
  int get coins;

  /// 过关所需金币数（随关卡递增）
  int get targetCoins;

  /// 是否游戏结束（含过关与失败）
  bool get isGameOver;

  /// 是否已达成过关条件
  bool get hasWon;

  /// HUD 右侧副信息（跑酷=距离，射击=剩余机会）
  String get statLabel;
  String get statValue;

  /// 重新开始（金币清零）
  void restart();

  /// 返回上一页（success=true 过关，false 失败）
  void quit(bool success);

  /// 调试信息（HUD 左下角小字显示，空串则不显示）
  String get debugText => '';
}
