package com.h.udemy.java.uservices.infrastructure.mqtt.config;

import com.h.udemy.java.uservices.infrastructure.mqtt.publisher.MqttPublisher;
import com.h.udemy.java.uservices.infrastructure.mqtt.subscriber.MqttSubscriber;
import com.h.udemy.java.uservices.infrastructure.mqtt.service.MqttService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.eclipse.paho.mqttv5.client.IMqttToken;
import org.eclipse.paho.mqttv5.client.MqttAsyncClient;
import org.eclipse.paho.mqttv5.client.MqttConnectionOptions;
import org.eclipse.paho.mqttv5.common.MqttException;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.nio.charset.StandardCharsets;

@Slf4j
@Configuration
@RequiredArgsConstructor
public class MqttConfiguration {

    private final ApiMqttProperties props;

    @Bean
    public MqttAsyncClient mqttClient() throws MqttException {
        log.info("Creating MQTT v5 client for broker: {}", props.getBrokerUrl());

        MqttAsyncClient client = new MqttAsyncClient(props.getBrokerUrl(), props.getClientId());
        MqttConnectionOptions options = new MqttConnectionOptions();

        options.setCleanStart(props.isCleanSession());
        options.setConnectionTimeout(props.getConnectionTimeout());
        options.setKeepAliveInterval(props.getKeepAliveInterval());
        
        // Authentication: Username/Password (for TLS) or mTLS certificates
        if (props.getUsername() != null && !props.getUsername().isEmpty()) {
            options.setUserName(props.getUsername());
        }
        if (props.getPassword() != null && !props.getPassword().isEmpty()) {
            options.setPassword(props.getPassword().getBytes(StandardCharsets.UTF_8));
        }
        
        // SSL/TLS configuration
        if (props.getBrokerUrl().startsWith("ssl://") || props.getBrokerUrl().startsWith("wss://")) {
            // SSL/TLS connection - certificates should be configured in JVM truststore/keystore
            // or via system properties: javax.net.ssl.trustStore, javax.net.ssl.keyStore
            log.info("Using SSL/TLS connection to: {}", props.getBrokerUrl());
        }

        // Connect the client
        IMqttToken connectToken = client.connect(options);
        connectToken.waitForCompletion();
        
        log.info("MQTT v5 client connected successfully");
        
        return client;
    }

    @Bean
    public MqttPublisher mqttPublisher(MqttAsyncClient mqttClient) {
        return new MqttPublisher(mqttClient, props);
    }

    @Bean
    public MqttSubscriber mqttSubscriber(MqttAsyncClient mqttClient) {
        MqttSubscriber subscriber = new MqttSubscriber(mqttClient, props);
        subscriber.setMessageCallback();
        return subscriber;
    }

    @Bean
    public MqttService mqttService(MqttPublisher mqttPublisher, MqttSubscriber mqttSubscriber) {
        return new MqttService(mqttPublisher, mqttSubscriber);
    }
}
