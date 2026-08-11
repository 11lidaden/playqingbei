package com.wanchuqingbei.config;

import com.wanchuqingbei.entity.GameType;
import com.wanchuqingbei.entity.LevelConfig;
import com.wanchuqingbei.repository.GameTypeRepository;
import com.wanchuqingbei.repository.LevelConfigRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class DataInitializer implements CommandLineRunner {

    private final GameTypeRepository gameTypeRepository;
    private final LevelConfigRepository levelConfigRepository;

    @Override
    public void run(String... args) {
        if (gameTypeRepository.count() == 0) {
            initGameTypes();
            initLevelConfigs();
            log.info("✅ 初始数据加载完成");
        }
    }

    private void initGameTypes() {
        gameTypeRepository.save(GameType.builder()
            .code("runner").name("跑酷").description("跑跳躲避障碍，到达终点即成功")
            .subject("all").gradeRange("all").assetPath("games/runner").build());

        gameTypeRepository.save(GameType.builder()
            .code("shooter").name("射击达人").description("打中正确答案的靶子")
            .subject("all").gradeRange("all").assetPath("games/shooter").build());

        gameTypeRepository.save(GameType.builder()
            .code("pipe").name("水管工").description("接通正确的数字水管")
            .subject("math").gradeRange("kindergarten,grade-1-2,grade-3-4").assetPath("games/pipe").build());

        gameTypeRepository.save(GameType.builder()
            .code("pinyin_train").name("拼音火车").description("拼对声母韵母，火车开走")
            .subject("chinese").gradeRange("kindergarten,grade-1-2").assetPath("games/pinyin_train").build());
    }

    private void initLevelConfigs() {
        String[] grades = {"kindergarten", "grade-1-2", "grade-3-4", "grade-5-6"};
        String[] subjects = {"chinese", "math", "english"};
        String[] gameCycle = {"runner", "shooter", "pipe", "pinyin_train", "runner"};

        int[] passRates = {3, 4, 4, 5};  // 各年级段过关正确数

        for (int gi = 0; gi < grades.length; gi++) {
            for (String subject : subjects) {
                for (int level = 1; level <= 10; level++) {
                    String gameCode = gameCycle[(level - 1) % gameCycle.length];

                    // 根据科目过滤不适用的游戏
                    if (("pipe".equals(gameCode) || "pinyin_train".equals(gameCode))
                        && !("chinese".equals(subject) || "math".equals(subject))) {
                        gameCode = "runner";
                    }

                    int passCount = passRates[gi];
                    levelConfigRepository.save(LevelConfig.builder()
                        .grade(grades[gi])
                        .subject(subject)
                        .level(level)
                        .levelName("第" + level + "关")
                        .gameCode(gameCode)
                        .star3Count(5)
                        .star2Count(4)
                        .passCount(passCount)
                        .sortOrder(level)
                        .build());
                }
            }
        }
    }
}
