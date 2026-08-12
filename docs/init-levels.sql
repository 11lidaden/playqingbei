-- 补充游戏类型
INSERT INTO game_types (code, name, description, subject, grade_range, asset_path) VALUES
('pipe', '水管工', '接通正确的数字水管', 'math', 'kindergarten,grade-1-2,grade-3-4', 'games/pipe'),
('pinyin_train', '拼音火车', '拼对声母韵母，火车开走', 'chinese', 'kindergarten,grade-1-2', 'games/pinyin_train')
ON DUPLICATE KEY UPDATE name=VALUES(name);

-- 关卡配置
INSERT INTO level_configs (grade, subject, level, level_name, game_code, star3_count, star2_count, pass_count, sort_order) VALUES
-- 幼儿园-语文
('kindergarten','chinese',1,'第1关','pinyin_train',5,4,3,1),
('kindergarten','chinese',2,'第2关','runner',5,4,3,2),
('kindergarten','chinese',3,'第3关','shooter',5,4,3,3),
('kindergarten','chinese',4,'第4关','pinyin_train',5,4,3,4),
('kindergarten','chinese',5,'第5关','runner',5,4,3,5),
-- 幼儿园-数学
('kindergarten','math',1,'第1关','pipe',5,4,3,1),
('kindergarten','math',2,'第2关','runner',5,4,3,2),
('kindergarten','math',3,'第3关','shooter',5,4,3,3),
('kindergarten','math',4,'第4关','pipe',5,4,3,4),
('kindergarten','math',5,'第5关','runner',5,4,3,5),
-- 幼儿园-英语
('kindergarten','english',1,'第1关','runner',5,4,3,1),
('kindergarten','english',2,'第2关','shooter',5,4,3,2),
('kindergarten','english',3,'第3关','runner',5,4,3,3),
('kindergarten','english',4,'第4关','shooter',5,4,3,4),
('kindergarten','english',5,'第5关','runner',5,4,3,5),
-- 1-2年级-语文
('grade-1-2','chinese',1,'第1关','pinyin_train',5,4,4,1),
('grade-1-2','chinese',2,'第2关','runner',5,4,4,2),
('grade-1-2','chinese',3,'第3关','shooter',5,4,4,3),
('grade-1-2','chinese',4,'第4关','pinyin_train',5,4,4,4),
('grade-1-2','chinese',5,'第5关','runner',5,4,4,5),
-- 1-2年级-数学
('grade-1-2','math',1,'第1关','pipe',5,4,4,1),
('grade-1-2','math',2,'第2关','runner',5,4,4,2),
('grade-1-2','math',3,'第3关','shooter',5,4,4,3),
('grade-1-2','math',4,'第4关','pipe',5,4,4,4),
('grade-1-2','math',5,'第5关','runner',5,4,4,5),
-- 1-2年级-英语
('grade-1-2','english',1,'第1关','runner',5,4,4,1),
('grade-1-2','english',2,'第2关','shooter',5,4,4,2),
('grade-1-2','english',3,'第3关','runner',5,4,4,3),
('grade-1-2','english',4,'第4关','shooter',5,4,4,4),
('grade-1-2','english',5,'第5关','runner',5,4,4,5),
-- 3-4年级-语文
('grade-3-4','chinese',1,'第1关','runner',5,4,4,1),
('grade-3-4','chinese',2,'第2关','shooter',5,4,4,2),
('grade-3-4','chinese',3,'第3关','runner',5,4,4,3),
('grade-3-4','chinese',4,'第4关','shooter',5,4,4,4),
('grade-3-4','chinese',5,'第5关','runner',5,4,4,5),
-- 3-4年级-数学
('grade-3-4','math',1,'第1关','pipe',5,4,4,1),
('grade-3-4','math',2,'第2关','runner',5,4,4,2),
('grade-3-4','math',3,'第3关','shooter',5,4,4,3),
('grade-3-4','math',4,'第4关','pipe',5,4,4,4),
('grade-3-4','math',5,'第5关','runner',5,4,4,5),
-- 3-4年级-英语
('grade-3-4','english',1,'第1关','runner',5,4,4,1),
('grade-3-4','english',2,'第2关','shooter',5,4,4,2),
('grade-3-4','english',3,'第3关','runner',5,4,4,3),
('grade-3-4','english',4,'第4关','shooter',5,4,4,4),
('grade-3-4','english',5,'第5关','runner',5,4,4,5),
-- 5-6年级-语文
('grade-5-6','chinese',1,'第1关','runner',5,4,5,1),
('grade-5-6','chinese',2,'第2关','shooter',5,4,5,2),
('grade-5-6','chinese',3,'第3关','runner',5,4,5,3),
('grade-5-6','chinese',4,'第4关','shooter',5,4,5,4),
('grade-5-6','chinese',5,'第5关','runner',5,4,5,5),
-- 5-6年级-数学
('grade-5-6','math',1,'第1关','runner',5,4,5,1),
('grade-5-6','math',2,'第2关','shooter',5,4,5,2),
('grade-5-6','math',3,'第3关','runner',5,4,5,3),
('grade-5-6','math',4,'第4关','shooter',5,4,5,4),
('grade-5-6','math',5,'第5关','runner',5,4,5,5),
-- 5-6年级-英语
('grade-5-6','english',1,'第1关','runner',5,4,5,1),
('grade-5-6','english',2,'第2关','shooter',5,4,5,2),
('grade-5-6','english',3,'第3关','runner',5,4,5,3),
('grade-5-6','english',4,'第4关','shooter',5,4,5,4),
('grade-5-6','english',5,'第5关','runner',5,4,5,5);
