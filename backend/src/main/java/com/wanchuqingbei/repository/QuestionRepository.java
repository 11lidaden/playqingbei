package com.wanchuqingbei.repository;

import com.wanchuqingbei.entity.Question;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

public interface QuestionRepository extends JpaRepository<Question, Long> {

    @Query("SELECT q FROM Question q WHERE q.grade = :grade AND q.subject = :subject AND q.level = :level ORDER BY q.sortOrder")
    List<Question> findByGradeAndSubjectAndLevel(
        @Param("grade") String grade,
        @Param("subject") String subject,
        @Param("level") Integer level
    );

    @Query("SELECT q FROM Question q WHERE q.grade = :grade AND q.subject = :subject AND q.level = :level ORDER BY FUNCTION('RAND')")
    List<Question> findRandomByGradeAndSubjectAndLevel(
        @Param("grade") String grade,
        @Param("subject") String subject,
        @Param("level") Integer level
    );
}
