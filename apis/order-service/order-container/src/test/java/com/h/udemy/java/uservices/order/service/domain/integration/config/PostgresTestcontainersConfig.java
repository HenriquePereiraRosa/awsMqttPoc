package com.h.udemy.java.uservices.order.service.domain.integration.config;

import org.springframework.boot.test.util.TestPropertyValues;
import org.springframework.context.ApplicationContextInitializer;
import org.springframework.context.ConfigurableApplicationContext;
import org.testcontainers.containers.KafkaContainer;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

/**
 * Testcontainers configuration for integration tests.
 * Automatically starts PostgreSQL and Kafka containers and provides connection properties.
 * Containers will be reused across test runs if available (withReuse(true)).
 */
public class PostgresTestcontainersConfig {

    private static PostgreSQLContainer<?> postgresContainer;
    private static KafkaContainer kafkaContainer;

    static {
        // PostgreSQL container
        postgresContainer = new PostgreSQLContainer<>(DockerImageName.parse("postgres:15-alpine"))
                .withDatabaseName("ordering_db")
                .withUsername("postgres")
                .withPassword("admin")
                .withInitScript("init-schema.sql")
                .withReuse(true); // Reuse container across test runs for faster execution
        postgresContainer.start();

        // Kafka container (single broker for testing - lighter than full cluster)
        kafkaContainer = new KafkaContainer(DockerImageName.parse("confluentinc/cp-kafka:7.5.0"))
                .withReuse(true); // Reuse container across test runs for faster execution
        kafkaContainer.start();
    }

    public static class Initializer implements ApplicationContextInitializer<ConfigurableApplicationContext> {
        @Override
        public void initialize(ConfigurableApplicationContext applicationContext) {
            // PostgreSQL configuration
            String jdbcUrl = postgresContainer.getJdbcUrl();
            String jdbcUrlWithSchema = jdbcUrl.contains("?") 
                    ? jdbcUrl + "&currentSchema=order" 
                    : jdbcUrl + "?currentSchema=order";
            
            // Kafka configuration
            String kafkaBootstrapServers = kafkaContainer.getBootstrapServers();
            
            TestPropertyValues.of(
                    // PostgreSQL properties
                    "spring.datasource.url=" + jdbcUrlWithSchema,
                    "spring.datasource.username=" + postgresContainer.getUsername(),
                    "spring.datasource.password=" + postgresContainer.getPassword(),
                    "spring.datasource.driver-class-name=" + postgresContainer.getDriverClassName(),
                    // Kafka properties
                    "kafka-config.bootstrap-servers=" + kafkaBootstrapServers,
                    "kafka-config.schema-registry-url=http://localhost:8081", // Schema Registry will need to be started separately or mocked
                    "kafka-config.num-of-partitions=1", // Single partition for tests
                    "kafka-config.replication-factor=1" // Single broker
            ).applyTo(applicationContext.getEnvironment());
        }
    }

    public static void stopContainers() {
        if (kafkaContainer != null && kafkaContainer.isRunning()) {
            kafkaContainer.stop();
        }
        if (postgresContainer != null && postgresContainer.isRunning()) {
            postgresContainer.stop();
        }
    }
}

