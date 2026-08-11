package com.wanchuqingbei.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "level_configs")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LevelConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 年级段 */
    @Column(nullable = false, length = 20)
    private String grade;

    /** 科目 */
    @Column(nullable = false, length = 20)
    private String subject;

    /** 关卡编号 */
    @Column(nullable = false)
    private Integer level;

    /** 关卡名称 */
    @Column(nullable = false, length = 50)
    private String levelName;

    /** 关联游戏类型code */
    @Column(nullable = false, length = 30)
    private String gameCode;

    /** 星级评价所需正确数 */
    @Column(nullable = false)
    private Integer star3Count;  // 三星: 全对
    private Integer star2Count;  // 二星: 错1题
    private Integer passCount;   // 过关: 最低正确数

    /** 关卡排序 */
    @Column(nullable = false)
    private Integer sortOrder;
}
