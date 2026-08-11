package com.wanchuqingbei.dto;

import lombok.Data;
import java.util.List;

@Data
public class AnswerRequest {
    private Long questionId;
    private String userAnswer;  // A/B/C/D
}
