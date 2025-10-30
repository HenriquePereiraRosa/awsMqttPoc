package com.h.udemy.java.uservices.infrastructure.mqtt.publisher;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.h.udemy.java.uservices.infrastructure.mqtt.config.ApiMqttProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.eclipse.paho.mqttv5.client.IMqttToken;
import org.eclipse.paho.mqttv5.client.MqttAsyncClient;
import org.eclipse.paho.mqttv5.common.MqttException;
import org.eclipse.paho.mqttv5.common.MqttMessage;
import org.eclipse.paho.mqttv5.common.packet.MqttProperties;
import org.springframework.stereotype.Component;

import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
public class MqttPublisher {

    private final MqttAsyncClient mqttClient;
    private final ApiMqttProperties mqttProperties;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public void publish(String topic, Object message) {
        publish(topic, message, mqttProperties.getQos(), mqttProperties.isRetained());
    }

    public void publish(String topic, Object message, int qos, boolean retained) {
        publish(topic, message, qos, retained, null, null);
    }

    public void publish(String topic, Object message, int qos, boolean retained, 
                       Map<String, String> userProperties, String contentType) {
        try {
            String jsonMessage = objectMapper.writeValueAsString(message);
            MqttMessage mqttMessage = new MqttMessage(jsonMessage.getBytes());
            mqttMessage.setQos(qos);
            mqttMessage.setRetained(retained);
            
            // MQTT v5 properties
            MqttProperties messageProperties = new MqttProperties();
            if (userProperties != null && !userProperties.isEmpty()) {
                // Note: User properties require UserProperty objects in Paho
                // For now, we'll skip this feature
                // messageProperties.setUserProperties(convertToUserPropertyList(userProperties));
            }
            if (contentType != null && !contentType.isEmpty()) {
                messageProperties.setContentType(contentType);
            }
            mqttMessage.setProperties(messageProperties);

            IMqttToken token = mqttClient.publish(topic, mqttMessage);
            token.waitForCompletion();
            
            log.info("Published message to topic '{}': {}", topic, jsonMessage);
        } catch (Exception e) {
            log.error("Failed to publish message to topic '{}': {}", topic, e.getMessage(), e);
            throw new RuntimeException("Failed to publish MQTT v5 message", e);
        }
    }

    public void publish(String topic, String message) {
        publish(topic, message, mqttProperties.getQos(), mqttProperties.isRetained());
    }

    public void publish(String topic, String message, int qos, boolean retained) {
        publish(topic, message, qos, retained, null, null);
    }

    public void publish(String topic, String message, int qos, boolean retained, 
                       Map<String, String> userProperties, String contentType) {
        try {
            MqttMessage mqttMessage = new MqttMessage(message.getBytes());
            mqttMessage.setQos(qos);
            mqttMessage.setRetained(retained);
            
            // MQTT v5 properties
            MqttProperties messageProperties = new MqttProperties();
            if (userProperties != null && !userProperties.isEmpty()) {
                // Note: User properties require UserProperty objects in Paho
                // For now, we'll skip this feature
                // messageProperties.setUserProperties(convertToUserPropertyList(userProperties));
            }
            if (contentType != null && !contentType.isEmpty()) {
                messageProperties.setContentType(contentType);
            }
            mqttMessage.setProperties(messageProperties);

            IMqttToken token = mqttClient.publish(topic, mqttMessage);
            token.waitForCompletion();
            
            log.info("Published message to topic '{}': {}", topic, message);
        } catch (MqttException e) {
            log.error("Failed to publish message to topic '{}': {}", topic, e.getMessage(), e);
            throw new RuntimeException("Failed to publish MQTT v5 message", e);
        }
    }

    public void publishWithResponse(String topic, Object message, String responseTopic, 
                                  byte[] correlationData) {
        try {
            String jsonMessage = objectMapper.writeValueAsString(message);
            MqttMessage mqttMessage = new MqttMessage(jsonMessage.getBytes());
            mqttMessage.setQos(mqttProperties.getQos());
            mqttMessage.setRetained(mqttProperties.isRetained());
            
            // MQTT v5 response properties
            MqttProperties messageProperties = new MqttProperties();
            messageProperties.setResponseTopic(responseTopic);
            messageProperties.setCorrelationData(correlationData);
            mqttMessage.setProperties(messageProperties);

            IMqttToken token = mqttClient.publish(topic, mqttMessage);
            token.waitForCompletion();
            
            log.info("Published message with response to topic '{}': {}", topic, jsonMessage);
        } catch (Exception e) {
            log.error("Failed to publish message with response to topic '{}': {}", topic, e.getMessage(), e);
            throw new RuntimeException("Failed to publish MQTT v5 message with response", e);
        }
    }

    public boolean isConnected() {
        return mqttClient.isConnected();
    }
}
