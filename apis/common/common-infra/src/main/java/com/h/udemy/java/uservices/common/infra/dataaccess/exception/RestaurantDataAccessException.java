package com.h.udemy.java.uservices.common.infra.dataaccess.exception;

public class RestaurantDataAccessException extends RuntimeException{

    public RestaurantDataAccessException(String message) {
        super(message);
    }
}
