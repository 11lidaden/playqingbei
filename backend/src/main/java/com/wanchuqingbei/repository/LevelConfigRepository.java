package com.wanchuqingbei.repository;

import com.wanchuqingbei.entity.LevelConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface LevelConfigRepository extends JpaRepository<LevelConfig, Long> {
    List<LevelConfig> findByGradeAndSubjectOrderBySortOrder(String grade, String subject);
}
