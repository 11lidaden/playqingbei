package com.wanchuqingbei.controller;

import com.wanchuqingbei.dto.*;
import com.wanchuqingbei.service.QuestionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
@CrossOrigin
@RequiredArgsConstructor
public class QuestionController {

    private final QuestionService questionService;

    /**
     * 获取关卡题目
     * GET /api/questions?grade=kindergarten&subject=chinese&level=1
     */
    @GetMapping("/questions")
    public ResponseEntity<List<QuestionDTO>> getQuestions(
            @RequestParam String grade,
            @RequestParam String subject,
            @RequestParam int level) {
        return ResponseEntity.ok(questionService.getQuestions(grade, subject, level));
    }

    /**
     * 提交关卡答案
     * POST /api/submit
     */
    @PostMapping("/submit")
    public ResponseEntity<LevelResult> submitAnswers(
            @RequestParam String grade,
            @RequestParam String subject,
            @RequestParam int level,
            @RequestBody List<AnswerRequest> answers) {
        return ResponseEntity.ok(questionService.submitAnswers(grade, subject, level, answers));
    }

    /**
     * 健康检查
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        return ResponseEntity.ok(Map.of("status", "ok", "app", "玩出清北"));
    }
}
