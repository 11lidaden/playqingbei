package com.wanchuqingbei.repository;

import com.wanchuqingbei.entity.GameType;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface GameTypeRepository extends JpaRepository<GameType, Long> {
    Optional<GameType> findByCode(String code);
}
