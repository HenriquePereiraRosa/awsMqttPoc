package com.h.udemy.java.uservices.common.infra.dataaccess.repository;

import com.h.udemy.java.uservices.common.infra.dataaccess.entity.RestaurantEntity;
import com.h.udemy.java.uservices.common.infra.dataaccess.entity.RestaurantEntityId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface RestaurantJpaRepository extends JpaRepository<RestaurantEntity, RestaurantEntityId> {

    Optional<List<RestaurantEntity>> findByRestaurantIdAndProductIdIn(UUID restaurantId, List<UUID> productIds);
}
