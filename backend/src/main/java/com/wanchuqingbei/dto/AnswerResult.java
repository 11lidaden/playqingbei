package com.wanchuqingbei.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AnswerResult {
    private Long questionId;
    private boolean correct;
    private String correctAnswer;
    private String explanation;
}
