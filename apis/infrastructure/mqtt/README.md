# MQTT Infrastructure Library

A Spring Boot-based MQTT infrastructure library that provides easy-to-use publishers and subscribers for MQTT communication using MQTT v5 protocol.

## Features

- **MQTT Publisher**: Publish messages to MQTT topics
- **MQTT Subscriber**: Subscribe to MQTT topics with message handlers
- **Universal Broker Support**: Works with any MQTT v5 compatible broker
- **Spring Boot Integration**: Auto-configuration and dependency injection
- **JSON Serialization**: Automatic JSON serialization/deserialization
- **Type-safe Subscriptions**: Subscribe with typed message handlers
- **Connection Management**: Automatic connection handling and reconnection

## Dependencies

Add the MQTT library to your `pom.xml`:

```xml
<dependency>
    <groupId>com.h.udemy.java.uservices</groupId>
    <artifactId>mqtt</artifactId>
    <version>1.0.0</version>
</dependency>
```

## Configuration

### Standard MQTT Configuration

```yaml
mqtt:
  broker-url: tcp://localhost:1883
  client-id: my-client-${random.uuid}
  username: ${MQTT_USERNAME:}
  password: ${MQTT_PASSWORD:}
  connection-timeout: 30
  keep-alive-interval: 60
  clean-session: true
  qos: 1
  retained: false
```

### SSL/TLS Configuration (for secure brokers)

```yaml
mqtt:
  broker-url: ssl://your-broker.com:8883
  client-id: your-client-id
  # SSL certificates handled by Java SSL context
```

## Usage

### Basic Publisher Usage

```java
@Service
@RequiredArgsConstructor
public class SensorService {
    
    private final MqttService mqttService;
    
    public void publishTemperature(double temperature) {
        TemperatureData data = new TemperatureData(temperature, System.currentTimeMillis());
        mqttService.publish("sensors/temperature", data);
    }
    
    public void publishCustomMessage(String topic, String message) {
        mqttService.publish(topic, message, 1, false);
    }
}
```

### Basic Subscriber Usage

```java
@Service
@RequiredArgsConstructor
public class DataProcessor {
    
    private final MqttService mqttService;
    
    @PostConstruct
    public void initializeSubscriptions() {
        // Subscribe to string messages
        mqttService.subscribe("sensors/temperature", this::handleTemperature);
        
        // Subscribe to typed messages
        mqttService.subscribe("sensors/humidity", HumidityData.class, this::handleHumidity);
        
        // Subscribe to raw MQTT messages
        mqttService.subscribeRaw("sensors/raw", this::handleRawMessage);
    }
    
    private void handleTemperature(String temperatureData) {
        log.info("Temperature received: {}", temperatureData);
    }
    
    private void handleHumidity(HumidityData humidityData) {
        log.info("Humidity received: {}", humidityData.getHumidity());
    }
    
    private void handleRawMessage(MqttMessage message) {
        log.info("Raw message: {}", new String(message.getPayload()));
    }
}
```

### Advanced Usage

```java
@Service
@RequiredArgsConstructor
public class AdvancedMqttService {
    
    private final MqttService mqttService;
    
    public void setupComplexSubscriptions() {
        // Subscribe with custom QoS
        mqttService.subscribe("important/topic", this::handleImportant, 2);
        
        // Subscribe to multiple topics
        List<String> topics = Arrays.asList("sensors/temp", "sensors/humidity", "sensors/pressure");
        topics.forEach(topic -> 
            mqttService.subscribe(topic, SensorData.class, this::handleSensorData)
        );
    }
    
    public void publishWithRetention(String topic, Object data) {
        mqttService.publish(topic, data, 1, true); // QoS 1, retained
    }
    
    public void checkConnection() {
        if (mqttService.isConnected()) {
            log.info("MQTT connection is active");
        } else {
            log.warn("MQTT connection is not active");
        }
    }
}
```

## Message Data Classes

Create your own data classes for type-safe message handling:

```java
@Data
@AllArgsConstructor
@NoArgsConstructor
public class SensorData {
    private String sensorId;
    private double value;
    private String unit;
    private long timestamp;
    private Map<String, Object> metadata;
}

@Data
@AllArgsConstructor
@NoArgsConstructor
public class DeviceCommand {
    private String deviceId;
    private String command;
    private Map<String, Object> parameters;
    private long timestamp;
}
```

## Broker Setup

### Local Development (Mosquitto)
```bash
# Install Mosquitto
docker run -it -p 1883:1883 -p 9001:9001 eclipse-mosquitto

# Or with SSL
docker run -it -p 8883:8883 -v /path/to/certs:/mosquitto/certs eclipse-mosquitto
```

### Production Brokers
- **HiveMQ Cloud**: Managed MQTT broker service
- **Eclipse Mosquitto**: Open source MQTT broker
- **EMQX**: High-performance MQTT broker
- **AWS IoT Core**: Cloud MQTT service (use standard MQTT v5)

## Error Handling

The library provides built-in error handling:

- **Connection Errors**: Automatic reconnection attempts
- **Publish Errors**: Exceptions are thrown for failed publishes
- **Subscribe Errors**: Exceptions are thrown for failed subscriptions
- **Message Processing Errors**: Individual message handler errors are logged

## Testing

```java
@SpringBootTest
class MqttServiceTest {
    
    @Autowired
    private MqttService mqttService;
    
    @Test
    void testPublishMessage() {
        assertDoesNotThrow(() -> {
            mqttService.publish("test/topic", "test message");
        });
    }
    
    @Test
    void testConnectionStatus() {
        assertTrue(mqttService.isConnected());
    }
}
```

## Best Practices

1. **Topic Naming**: Use hierarchical topic structure (e.g., `sensors/temperature/device-001`)
2. **QoS Levels**: Use appropriate QoS levels (0 for fire-and-forget, 1 for at-least-once, 2 for exactly-once)
3. **Message Size**: Keep messages small for better performance
4. **Error Handling**: Always handle exceptions in message handlers
5. **Connection Management**: Check connection status before publishing
6. **Resource Cleanup**: Unsubscribe from topics when no longer needed

## Troubleshooting

### Common Issues

1. **Connection Failed**: Check broker URL and credentials
2. **Messages Not Received**: Verify topic subscriptions and QoS levels
3. **SSL/TLS Issues**: Verify certificates and broker SSL configuration
4. **Serialization Errors**: Ensure message classes have proper constructors

### Debug Logging

Enable debug logging to troubleshoot issues:

```yaml
logging:
  level:
    com.h.udemy.java.uservices.infrastructure.mqtt: DEBUG
    org.eclipse.paho: DEBUG
```

## License

This library is part of the MQTT POC project.

