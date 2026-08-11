package com.wanchuqingbei.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LevelResult {
    private int correctCount;
    private int totalCount;
    private boolean passed;
    private int stars;  // 0-3
    private String gameCode;  // 解锁的游戏
    private List<AnswerResult> details;
}
