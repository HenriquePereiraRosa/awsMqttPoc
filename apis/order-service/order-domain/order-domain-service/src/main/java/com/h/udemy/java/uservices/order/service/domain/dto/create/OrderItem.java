package com.h.udemy.java.uservices.order.service.domain.dto.create;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.math.BigDecimal;
import java.util.UUID;

@Getter
@Builder
@AllArgsConstructor
public class OrderItem {

    @NotNull
    private final UUID productId;
    @NotNull
    private final Integer quantity;
    @NotNull
    private final BigDecimal price;

    public BigDecimal getSubtotal() {
        return price.multiply(new BigDecimal(quantity));
    }

}
