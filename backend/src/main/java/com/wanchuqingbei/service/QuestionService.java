package com.wanchuqingbei.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.wanchuqingbei.dto.*;
import com.wanchuqingbei.entity.LevelConfig;
import com.wanchuqingbei.entity.Question;
import com.wanchuqingbei.repository.LevelConfigRepository;
import com.wanchuqingbei.repository.QuestionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class QuestionService {

    private final QuestionRepository questionRepository;
    private final LevelConfigRepository levelConfigRepository;
    private final ObjectMapper objectMapper;

    /**
     * 获取指定关卡的题目（随机抽取，不返回答案）
     */
    public List<QuestionDTO> getQuestions(String grade, String subject, int level) {
        List<Question> questions = questionRepository.findRandomByGradeAndSubjectAndLevel(grade, subject, level);
        return questions.stream().map(q -> {
            try {
                List<String> options = objectMapper.readValue(q.getOptions(), new TypeReference<>() {});
                return new QuestionDTO(q.getId(), q.getContent(), options);
            } catch (Exception e) {
                return new QuestionDTO(q.getId(), q.getContent(), List.of());
            }
        }).toList();
    }

    /**
     * 提交答案，判定过关结果
     */
    public LevelResult submitAnswers(String grade, String subject, int level, List<AnswerRequest> answers) {
        List<AnswerResult> details = new ArrayList<>();
        int correctCount = 0;

        for (AnswerRequest req : answers) {
            Question q = questionRepository.findById(req.getQuestionId()).orElse(null);
            if (q == null) continue;

            boolean correct = q.getAnswer().equalsIgnoreCase(req.getUserAnswer());
            if (correct) correctCount++;

            details.add(new AnswerResult(
                req.getQuestionId(),
                correct,
                q.getAnswer(),
                q.getExplanation()
            ));
        }

        // 查关卡配置
        LevelConfig config = levelConfigRepository
            .findByGradeAndSubjectOrderBySortOrder(grade, subject)
            .stream()
            .filter(lc -> lc.getLevel() == level)
            .findFirst()
            .orElse(null);

        int passCount = config != null ? config.getPassCount() : 3;
        int star2Count = config != null ? config.getStar2Count() : 4;
        int star3Count = config != null ? config.getStar3Count() : 5;
        String gameCode = config != null ? config.getGameCode() : "runner";

        boolean passed = correctCount >= passCount;
        int stars = 0;
        if (passed) {
            if (correctCount >= star3Count) stars = 3;
            else if (correctCount >= star2Count) stars = 2;
            else stars = 1;
        }

        return new LevelResult(correctCount, answers.size(), passed, stars, gameCode, details);
    }
}
