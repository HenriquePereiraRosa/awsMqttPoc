package com.h.udemy.java.uservices.order.service.dataaccess;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.junit.jupiter.api.Test;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;
import org.springframework.boot.autoconfigure.jdbc.DataSourceTransactionManagerAutoConfiguration;
import org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration;
import org.springframework.boot.test.context.SpringBootTest;

import static com.h.udemy.java.uservices.order.service.domain.messages.log.LogMessages.APP_NAME_DESCRIPTION;

@Slf4j
@SpringBootTest(classes = BeanTestConfig.class,
        webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@EnableAutoConfiguration(exclude = {
        DataSourceAutoConfiguration.class,
        DataSourceTransactionManagerAutoConfiguration.class,
        HibernateJpaAutoConfiguration.class
})
public abstract class ApiEnvTestConfig {
    public ObjectMapper mapper = new ObjectMapper();

    @PostConstruct
    void setup() {
        mapper.registerModule(new JavaTimeModule());
        mapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
    }

    @Test
    void contextLoads() {
       log.debug(APP_NAME_DESCRIPTION.get());
       log.info(APP_NAME_DESCRIPTION.get());
       log.warn(APP_NAME_DESCRIPTION.get());
       log.error(APP_NAME_DESCRIPTION.get());
    }

}
