package com.wanchuqingbei.controller;

import com.wanchuqingbei.entity.LevelConfig;
import com.wanchuqingbei.entity.GameType;
import com.wanchuqingbei.repository.LevelConfigRepository;
import com.wanchuqingbei.repository.GameTypeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
@CrossOrigin
@RequiredArgsConstructor
public class LevelController {

    private final LevelConfigRepository levelConfigRepository;
    private final GameTypeRepository gameTypeRepository;

    /**
     * 获取指定年级科目的所有关卡
     * GET /api/levels?grade=kindergarten&subject=chinese
     */
    @GetMapping("/levels")
    public ResponseEntity<List<LevelConfig>> getLevels(
            @RequestParam String grade,
            @RequestParam String subject) {
        return ResponseEntity.ok(levelConfigRepository.findByGradeAndSubjectOrderBySortOrder(grade, subject));
    }

    /**
     * 获取所有游戏类型
     * GET /api/games
     */
    @GetMapping("/games")
    public ResponseEntity<List<GameType>> getGameTypes() {
        return ResponseEntity.ok(gameTypeRepository.findAll());
    }
}
