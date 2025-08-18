package com.h.udemy.java.uservices.order.service.dataaccess.order.adapter;

import com.h.udemy.java.uservices.domain.valueobject.OrderId;
import com.h.udemy.java.uservices.order.service.dataaccess.order.entity.OrderEntity;
import com.h.udemy.java.uservices.order.service.dataaccess.order.mapper.OrderDataAccessMapper;
import com.h.udemy.java.uservices.order.service.dataaccess.order.repository.OrderJpaRepository;
import com.h.udemy.java.uservices.order.service.domain.entity.Order;
import com.h.udemy.java.uservices.order.service.domain.ports.output.repository.OrderRepository;
import com.h.udemy.java.uservices.order.service.domain.valueobject.TrackingId;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

@Component
public class OrderRepositoryI implements OrderRepository {

    private final OrderJpaRepository orderJpaRepository;
    private final OrderDataAccessMapper orderDataAccessMapper;

    public OrderRepositoryI(OrderJpaRepository orderJpaRepository,
                            OrderDataAccessMapper orderDataAccessMapper) {
        this.orderJpaRepository = orderJpaRepository;
        this.orderDataAccessMapper = orderDataAccessMapper;
    }

    @Override
    public Order insertOrder(Order order) {
        return orderDataAccessMapper.orderEntityToOrder(orderJpaRepository
                .save(orderDataAccessMapper.orderToOrderEntity(order)));
    }

    @Override
    public Optional<Order> findByTrackingId(TrackingId trackingId) {
        return orderJpaRepository.findByTrackingId(trackingId.getValue())
                .map(orderDataAccessMapper::orderEntityToOrder);
    }

    @Override
    public Optional<Order> findById(OrderId orderId) {
        return orderJpaRepository.findById(orderId.getValue())
                .map(orderDataAccessMapper::orderEntityToOrder);
    }

    @Override
    public List<Order> fetchAll() {
        return orderJpaRepository.findAll()
                .stream()
                .map(orderDataAccessMapper::orderEntityToOrder)
                .toList();
    }

    @Override
    public Order save(Order order) {
        final OrderEntity orderEntity =orderDataAccessMapper.orderToOrderEntity(order);

        return orderDataAccessMapper
                .orderEntityToOrder(orderJpaRepository.save(orderEntity));
    }
}
