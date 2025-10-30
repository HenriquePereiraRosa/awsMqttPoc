package com.h.udemy.java.uservices.infrastructure.mqtt.service;

import com.h.udemy.java.uservices.infrastructure.mqtt.publisher.MqttPublisher;
import com.h.udemy.java.uservices.infrastructure.mqtt.subscriber.MqttSubscriber;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.function.Consumer;

@Slf4j
@Service
@RequiredArgsConstructor
public class MqttService {

    private final MqttPublisher mqttPublisher;
    private final MqttSubscriber mqttSubscriber;

    public void publish(String topic, Object message) {
        mqttPublisher.publish(topic, message);
    }

    public void publish(String topic, String message) {
        mqttPublisher.publish(topic, message);
    }

    public void publish(String topic, Object message, int qos, boolean retained) {
        mqttPublisher.publish(topic, message, qos, retained);
    }

    public void publish(String topic, Object message, int qos, boolean retained, 
                       Map<String, String> userProperties, String contentType) {
        mqttPublisher.publish(topic, message, qos, retained, userProperties, contentType);
    }

    public void publishWithResponse(String topic, Object message, String responseTopic, 
                                  byte[] correlationData) {
        mqttPublisher.publishWithResponse(topic, message, responseTopic, correlationData);
    }

    public void subscribe(String topic) {
        mqttSubscriber.subscribe(topic);
    }

    public void subscribe(String topic, Consumer<String> messageHandler) {
        mqttSubscriber.subscribe(topic, messageHandler);
    }

    public <T> void subscribe(String topic, Class<T> messageType, Consumer<T> messageHandler) {
        mqttSubscriber.subscribe(topic, messageType, messageHandler);
    }

    public void subscribeRaw(String topic, Consumer<org.eclipse.paho.mqttv5.common.MqttMessage> messageHandler) {
        mqttSubscriber.subscribeRaw(topic, messageHandler);
    }

    public void subscribeV5(String topic, Consumer<MqttSubscriber.MqttV5Message> messageHandler) {
        mqttSubscriber.subscribeV5(topic, messageHandler);
    }

    public void unsubscribe(String topic) {
        mqttSubscriber.unsubscribe(topic);
    }

    public boolean isConnected() {
        return mqttPublisher.isConnected() && mqttSubscriber.isConnected();
    }
}
