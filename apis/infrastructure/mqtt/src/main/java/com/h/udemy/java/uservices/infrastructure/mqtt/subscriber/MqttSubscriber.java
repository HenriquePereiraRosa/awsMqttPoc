package com.h.udemy.java.uservices.infrastructure.mqtt.subscriber;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.h.udemy.java.uservices.infrastructure.mqtt.config.ApiMqttProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.eclipse.paho.mqttv5.client.*;
import org.eclipse.paho.mqttv5.common.MqttException;
import org.eclipse.paho.mqttv5.common.MqttMessage;
import org.eclipse.paho.mqttv5.common.packet.MqttProperties;
import org.springframework.stereotype.Component;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.function.Consumer;

@Slf4j
@Component
@RequiredArgsConstructor
public class MqttSubscriber {

    private final MqttAsyncClient mqttClient;
    private final ApiMqttProperties mqttProperties;
    private final ObjectMapper objectMapper = new ObjectMapper();
    
    private final ConcurrentHashMap<String, CopyOnWriteArrayList<Consumer<String>>> topicSubscribers = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, CopyOnWriteArrayList<Consumer<MqttMessage>>> rawTopicSubscribers = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, CopyOnWriteArrayList<Consumer<MqttV5Message>>> v5TopicSubscribers = new ConcurrentHashMap<>();

    public void subscribe(String topic) {
        subscribe(topic, mqttProperties.getQos());
    }

    public void subscribe(String topic, int qos) {
        try {
            IMqttToken token = mqttClient.subscribe(topic, qos);
            token.waitForCompletion();
            log.info("Subscribed to topic: {}", topic);
        } catch (MqttException e) {
            log.error("Failed to subscribe to topic '{}': {}", topic, e.getMessage(), e);
            throw new RuntimeException("Failed to subscribe to MQTT v5 topic", e);
        }
    }

    public void subscribe(String topic, Consumer<String> messageHandler) {
        subscribe(topic, messageHandler, mqttProperties.getQos());
    }

    public void subscribe(String topic, Consumer<String> messageHandler, int qos) {
        topicSubscribers.computeIfAbsent(topic, k -> new CopyOnWriteArrayList<>()).add(messageHandler);
        subscribe(topic, qos);
    }

    public void subscribeRaw(String topic, Consumer<MqttMessage> messageHandler) {
        subscribeRaw(topic, messageHandler, mqttProperties.getQos());
    }

    public void subscribeRaw(String topic, Consumer<MqttMessage> messageHandler, int qos) {
        rawTopicSubscribers.computeIfAbsent(topic, k -> new CopyOnWriteArrayList<>()).add(messageHandler);
        subscribe(topic, qos);
    }

    public void subscribeV5(String topic, Consumer<MqttV5Message> messageHandler) {
        subscribeV5(topic, messageHandler, mqttProperties.getQos());
    }

    public void subscribeV5(String topic, Consumer<MqttV5Message> messageHandler, int qos) {
        v5TopicSubscribers.computeIfAbsent(topic, k -> new CopyOnWriteArrayList<>()).add(messageHandler);
        subscribe(topic, qos);
    }

    public void unsubscribe(String topic) {
        try {
            IMqttToken token = mqttClient.unsubscribe(topic);
            token.waitForCompletion();
            topicSubscribers.remove(topic);
            rawTopicSubscribers.remove(topic);
            v5TopicSubscribers.remove(topic);
            log.info("Unsubscribed from topic: {}", topic);
        } catch (MqttException e) {
            log.error("Failed to unsubscribe from topic '{}': {}", topic, e.getMessage(), e);
            throw new RuntimeException("Failed to unsubscribe from MQTT v5 topic", e);
        }
    }

    public void setMessageCallback() {
        mqttClient.setCallback(new MqttCallback() {
            @Override
            public void disconnected(MqttDisconnectResponse disconnectResponse) {
                log.warn("MQTT v5 connection lost: {}", 
                    disconnectResponse != null ? disconnectResponse.getReasonString() : "Unknown reason");
            }

            @Override
            public void mqttErrorOccurred(MqttException exception) {
                log.error("MQTT v5 error occurred: {}", exception.getMessage(), exception);
            }

            @Override
            public void messageArrived(String topic, MqttMessage message) throws Exception {
                log.debug("Message arrived on topic '{}': {}", topic, new String(message.getPayload()));
                
                // Handle string message subscribers
                topicSubscribers.getOrDefault(topic, new CopyOnWriteArrayList<>())
                    .forEach(handler -> {
                        try {
                            handler.accept(new String(message.getPayload()));
                        } catch (Exception e) {
                            log.error("Error processing message for topic '{}': {}", topic, e.getMessage(), e);
                        }
                    });
                
                // Handle raw message subscribers
                rawTopicSubscribers.getOrDefault(topic, new CopyOnWriteArrayList<>())
                    .forEach(handler -> {
                        try {
                            handler.accept(message);
                        } catch (Exception e) {
                            log.error("Error processing raw message for topic '{}': {}", topic, e.getMessage(), e);
                        }
                    });
                
                // Handle MQTT v5 message subscribers
                v5TopicSubscribers.getOrDefault(topic, new CopyOnWriteArrayList<>())
                    .forEach(handler -> {
                        try {
                            MqttV5Message v5Message = new MqttV5Message(message);
                            handler.accept(v5Message);
                        } catch (Exception e) {
                            log.error("Error processing MQTT v5 message for topic '{}': {}", topic, e.getMessage(), e);
                        }
                    });
            }

            @Override
            public void deliveryComplete(IMqttToken token) {
                log.debug("Message delivery complete for message ID: {}", token.getMessageId());
            }

            @Override
            public void connectComplete(boolean reconnect, String serverURI) {
                log.info("MQTT v5 connection complete. Reconnect: {}, Server: {}", reconnect, serverURI);
            }

            @Override
            public void authPacketArrived(int reasonCode, MqttProperties properties) {
                log.debug("MQTT v5 auth packet arrived. Reason code: {}", reasonCode);
            }
        });
    }

    public <T> void subscribe(String topic, Class<T> messageType, Consumer<T> messageHandler) {
        subscribe(topic, messageType, messageHandler, mqttProperties.getQos());
    }

    public <T> void subscribe(String topic, Class<T> messageType, Consumer<T> messageHandler, int qos) {
        subscribe(topic, jsonMessage -> {
            try {
                T message = objectMapper.readValue(jsonMessage, messageType);
                messageHandler.accept(message);
            } catch (Exception e) {
                log.error("Failed to deserialize message for topic '{}': {}", topic, e.getMessage(), e);
            }
        }, qos);
    }

    public boolean isConnected() {
        return mqttClient.isConnected();
    }

    // MQTT v5 message wrapper with enhanced properties
    public static class MqttV5Message {
        private final MqttMessage message;
        private final MqttProperties properties;

        public MqttV5Message(MqttMessage message) {
            this.message = message;
            this.properties = message.getProperties();
        }

        public byte[] getPayload() {
            return message.getPayload();
        }

        public String getPayloadAsString() {
            return new String(message.getPayload());
        }

        public int getQos() {
            return message.getQos();
        }

        public boolean isRetained() {
            return message.isRetained();
        }

        public boolean isDuplicate() {
            return message.isDuplicate();
        }

        public MqttProperties getProperties() {
            return properties;
        }

        public String getContentType() {
            return properties != null ? properties.getContentType() : null;
        }

        public String getResponseTopic() {
            return properties != null ? properties.getResponseTopic() : null;
        }

        public byte[] getCorrelationData() {
            return properties != null ? properties.getCorrelationData() : null;
        }

        public java.util.Map<String, String> getUserProperties() {
            // Note: Paho MqttProperties returns List<UserProperty>, not Map
            // For now, return empty map - this would need conversion logic
            return new java.util.HashMap<>();
        }

        public String getUserProperty(String key) {
            // Note: Paho MqttProperties returns List<UserProperty>, not Map
            // For now, return null - this would need conversion logic
            return null;
        }
    }
}
