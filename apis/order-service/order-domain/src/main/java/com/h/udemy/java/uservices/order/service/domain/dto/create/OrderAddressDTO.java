package com.h.udemy.java.uservices.order.service.domain.dto.create;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@AllArgsConstructor
public class OrderAddressDTO {

    @NotNull
    @Max(value = 50)
    private final String street;
    @NotNull
    @Max(value = 50)
    private final String city;
    @NotNull
    @Max(value = 10)
    private final String postalCode;

}
