package com.h.udemy.java.uservices.common.infra.exception.handler.model;

import lombok.Builder;


@Builder
public record ErrorTo(String code, String message) {

}
