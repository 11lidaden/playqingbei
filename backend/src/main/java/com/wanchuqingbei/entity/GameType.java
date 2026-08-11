package com.wanchuqingbei.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "game_types")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GameType {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 游戏标识: runner, shooter, pipe, pinyin_train */
    @Column(nullable = false, unique = true, length = 30)
    private String code;

    /** 游戏名称 */
    @Column(nullable = false, length = 50)
    private String name;

    /** 游戏描述 */
    @Column(columnDefinition = "TEXT")
    private String description;

    /** 适用科目: all, chinese, math, english */
    @Column(nullable = false, length = 20)
    private String subject;

    /** 适用年级段: all, kindergarten, grade-1-2, ... */
    @Column(nullable = false, length = 30)
    private String gradeRange;

    /** 游戏资源路径 */
    @Column(length = 200)
    private String assetPath;
}
