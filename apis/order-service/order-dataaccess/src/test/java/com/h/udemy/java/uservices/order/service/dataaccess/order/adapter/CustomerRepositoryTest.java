package com.h.udemy.java.uservices.order.service.dataaccess.order.adapter;

import com.h.udemy.java.uservices.domain.valueobject.*;
import com.h.udemy.java.uservices.order.service.dataaccess.ApiEnvTestConfig;
import com.h.udemy.java.uservices.order.service.dataaccess.order.entity.OrderAddressEntity;
import com.h.udemy.java.uservices.order.service.dataaccess.order.entity.OrderEntity;
import com.h.udemy.java.uservices.order.service.dataaccess.order.entity.OrderItemEntity;
import com.h.udemy.java.uservices.order.service.dataaccess.order.repository.OrderJpaRepository;
import com.h.udemy.java.uservices.order.service.domain.entity.Order;
import com.h.udemy.java.uservices.order.service.domain.entity.OrderItem;
import com.h.udemy.java.uservices.order.service.domain.entity.Product;
import com.h.udemy.java.uservices.order.service.domain.ports.output.repository.OrderRepository;
import com.h.udemy.java.uservices.order.service.domain.valueobject.OrderItemId;
import com.h.udemy.java.uservices.order.service.domain.valueobject.StreetAddress;
import com.h.udemy.java.uservices.order.service.domain.valueobject.TrackingId;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestInstance;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.AssertionsForClassTypes.assertThat;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@TestInstance(TestInstance.Lifecycle.PER_CLASS)
class CustomerRepositoryTest extends ApiEnvTestConfig {

    private static final OrderId ORDER_ID = new OrderId(UUID.randomUUID());
    private final TrackingId TRACKING_ID = new TrackingId(UUID.randomUUID());

    @Autowired
    OrderRepository orderRepository;

    @Autowired
    OrderJpaRepository orderJpaRepository;


    private final Order order = this.createOneOrder();
    private final OrderEntity orderEntity = this.createOneOrderEntity();

    @BeforeAll
    public void setup(){

        when(orderJpaRepository.save(any(OrderEntity.class)))
                .thenReturn(orderEntity);

        when(orderJpaRepository.findByTrackingId(any(UUID.class)))
                .thenReturn(Optional.of(orderEntity));
    }

    @Test
    void insertOrder() {

        Order dummyOrder = this.createOneOrder();

        Order orderDb = orderRepository.insertOrder(dummyOrder);

        assertEquals(dummyOrder.getPrice(), orderDb.getPrice());
    }

    @Test
    void findByTrackingId() {

        Order dummyOrder = this.createOneOrder();

        final Optional<Order> orderDb = orderRepository.findByTrackingId(TRACKING_ID);

        assertThat(orderDb.isPresent()).isTrue();
        assertEquals(dummyOrder.getPrice(), orderDb.get().getPrice());
        assertThat(dummyOrder.getTrackingId()).isNotNull();
    }


    private Order createOneOrder() {

        StreetAddress address = new StreetAddress(UUID.randomUUID(),
                "sweet street",
                "01234-99",
                "Tokio");

        OrderItem item = OrderItem.builder()
                .orderItemId(new OrderItemId(112L))
                .product(new Product(new ProductId(UUID.randomUUID()),
                        "product name",
                        new Money(new BigDecimal("10.99"))))
                .price(new Money(new BigDecimal("10.99")))
                .quantity(5)
                .build();

        return Order.builder()
                .orderId(ORDER_ID)
                .customerId(new CustomerId(UUID.randomUUID()))
                .restaurantId(new RestaurantId(UUID.randomUUID()))
                .deliveryAddress(address)
                .price(new Money(new BigDecimal("54.95")))
                .items(List.of(item))
                .trackingId(TRACKING_ID)
                .build();
    }


    private OrderEntity createOneOrderEntity() {

        OrderAddressEntity address = new OrderAddressEntity(UUID.randomUUID(),
                null,
                "sweet street",
                "01234-99",
                "Tokio");

        OrderItemEntity item = OrderItemEntity.builder()
                .price(new BigDecimal("10.99"))
                .quantity(5)
                .build();

        return OrderEntity.builder()
                .customerId(UUID.randomUUID())
                .restaurantId(UUID.randomUUID())
                .address(address)
                .price(new BigDecimal("54.95"))
                .items(List.of(item))
                .trackingId(UUID.randomUUID())
                .build();
    }
}