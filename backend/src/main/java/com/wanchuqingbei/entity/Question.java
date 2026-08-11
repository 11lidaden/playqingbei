package com.wanchuqingbei.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "questions")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Question {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 年级段: kindergarten, grade-1-2, grade-3-4, grade-5-6 */
    @Column(nullable = false, length = 20)
    private String grade;

    /** 科目: chinese, math, english */
    @Column(nullable = false, length = 20)
    private String subject;

    /** 关卡编号 1-20 */
    @Column(nullable = false)
    private Integer level;

    /** 题目内容 */
    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    /** 选项JSON: ["A选项","B选项","C选项","D选项"] */
    @Column(nullable = false, columnDefinition = "JSON")
    private String options;

    /** 正确答案: A/B/C/D */
    @Column(nullable = false, length = 5)
    private String answer;

    /** 答案解析 */
    @Column(columnDefinition = "TEXT")
    private String explanation;

    /** 难度 1-5 */
    @Column(nullable = false)
    private Integer difficulty;

    /** 排序号（同一关内题目顺序） */
    @Column(nullable = false)
    private Integer sortOrder;
}
