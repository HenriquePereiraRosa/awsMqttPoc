package com.h.udemy.java.uservices.order.service.dataaccess;

import com.h.udemy.java.uservices.common.infra.dataaccess.repository.RestaurantJpaRepository;
import com.h.udemy.java.uservices.order.service.dataaccess.customer.repository.CustomerJpaRepository;
import com.h.udemy.java.uservices.order.service.dataaccess.order.repository.OrderJpaRepository;
import com.h.udemy.java.uservices.order.service.dataaccess.outbox.payment.repository.PaymentOutboxJpaRepository;
import com.h.udemy.java.uservices.order.service.dataaccess.outbox.restaurantapproval.repository.ApprovalOutboxJpaRepository;
import org.mockito.Mockito;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;

@SpringBootApplication(scanBasePackages = "com.h.udemy.java.uservices.order.service.dataaccess")
public class BeanTestConfig {

    @Bean
    public RestaurantJpaRepository restaurantJpaRepository() {
        return Mockito.mock(RestaurantJpaRepository.class);
    }
    @Bean
    @Primary
    public OrderJpaRepository orderJpaRepository() {
        return Mockito.mock(OrderJpaRepository.class);
    }
    @Bean
    public CustomerJpaRepository customerJpaRepository() {
        return Mockito.mock(CustomerJpaRepository.class);
    }
    @Bean
    public PaymentOutboxJpaRepository paymentOutboxJpaRepository() {
        return Mockito.mock(PaymentOutboxJpaRepository.class);
    }
    @Bean
    public ApprovalOutboxJpaRepository approvalOutboxJpaRepository() {
        return Mockito.mock(ApprovalOutboxJpaRepository.class);
    }

}
