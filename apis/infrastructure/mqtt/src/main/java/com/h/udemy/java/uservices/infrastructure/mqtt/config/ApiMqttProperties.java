package com.h.udemy.java.uservices.infrastructure.mqtt.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Data
@Component
@ConfigurationProperties(prefix = "mqtt")
public class ApiMqttProperties {
    
    private String brokerUrl;
    private String clientId;
    private String username;
    private String password;
    private int connectionTimeout = 30;
    private int keepAliveInterval = 60;
    private boolean cleanSession = true;
    private int qos = 1;
    private boolean retained = false;
    
    private MqttV5 mqttV5 = new MqttV5();
    
    @Data
    public static class MqttV5 {
        private long sessionExpiryInterval = 0; // 0 = no expiry
        private int receiveMaximum = 65535; // No limit
        private long maximumPacketSize = 0; // No limit
        private int topicAliasMaximum = 0; // No aliases
        private int willDelayInterval = 0;
    }
    
}

