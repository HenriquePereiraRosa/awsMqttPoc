# MQTT v5 Features and Migration Guide

## 🚀 MQTT v5 Upgrade Complete!

The MQTT infrastructure library has been upgraded to support **MQTT v5** with full backward compatibility for MQTT v3.1.1.

## ✨ New MQTT v5 Features

### 1. **Enhanced Message Properties**
- **User Properties**: Custom key-value pairs attached to messages
- **Content Type**: MIME type specification for message content
- **Response Topic**: Built-in request-response pattern support
- **Correlation Data**: Message correlation for request-response flows

### 2. **Improved Connection Management**
- **Session Expiry**: Configurable session persistence
- **Receive Maximum**: Flow control for incoming messages
- **Maximum Packet Size**: Configurable packet size limits
- **Topic Alias Maximum**: Topic name optimization

### 3. **Better Error Handling**
- **Reason Codes**: Detailed error reporting
- **Problem Information**: Enhanced debugging capabilities
- **Disconnect with Reason**: Graceful disconnection with reasons

### 4. **Request-Response Pattern**
- **Response Topic**: Automatic response routing
- **Correlation Data**: Message tracking across requests/responses
- **Built-in Support**: No need for custom correlation mechanisms

## 🔧 Configuration

### Enable MQTT v5 (Default)
```yaml
mqtt:
  use-mqtt-v5: true  # Default is true
```

### Use MQTT v3.1.1 (Legacy)
```yaml
mqtt:
  use-mqtt-v5: false
```

### MQTT v5 Specific Configuration
```yaml
mqtt:
  mqtt-v5:
    session-expiry-interval: 0      # 0 = no expiry
    receive-maximum: 65535          # No limit
    maximum-packet-size: 0          # No limit
    topic-alias-maximum: 0          # No aliases
    request-response-information: false
    request-problem-information: true
    user-properties:
      application: "mqttpoc"
      version: "1.0.0"
    will-delay-interval: 0
    content-type: "application/json"
```

## 📝 Usage Examples

### Basic MQTT v5 Usage
```java
@Service
public class MyService {
    private final MqttV5Service mqttV5Service;
    
    public void publishData(Object data) {
        // Basic publish
        mqttV5Service.publish("my/topic", data);
        
        // Publish with MQTT v5 properties
        Map<String, String> userProperties = new HashMap<>();
        userProperties.put("source", "sensor-001");
        userProperties.put("priority", "high");
        
        mqttV5Service.publish("my/topic", data, 1, false, 
                             userProperties, "application/json");
    }
}
```

### Request-Response Pattern
```java
public void sendCommand(String deviceId, String command) {
    String topic = "commands/device/" + deviceId;
    String responseTopic = "responses/device/" + deviceId;
    byte[] correlationData = UUID.randomUUID().toString().getBytes();
    
    DeviceCommand cmd = new DeviceCommand(deviceId, command);
    mqttV5Service.publishWithResponse(topic, cmd, responseTopic, correlationData);
}

public void handleResponse() {
    mqttV5Service.subscribeV5("responses/device/+", message -> {
        log.info("Response received: {}", message.getPayloadAsString());
        log.info("Correlation data: {}", new String(message.getCorrelationData()));
    });
}
```

### Advanced Message Handling
```java
public void handleAdvancedMessages() {
    mqttV5Service.subscribeV5("sensors/+", message -> {
        // Access MQTT v5 properties
        String contentType = message.getContentType();
        Map<String, String> userProps = message.getUserProperties();
        String responseTopic = message.getResponseTopic();
        byte[] correlationData = message.getCorrelationData();
        
        log.info("Content Type: {}", contentType);
        log.info("User Properties: {}", userProps);
        
        // Process message based on properties
        if ("application/json".equals(contentType)) {
            // Handle JSON message
        }
    });
}
```

## 🔄 Migration from MQTT v3.1.1

### 1. **Automatic Migration**
The library automatically uses MQTT v5 by default. No code changes required!

### 2. **Gradual Migration**
You can run both versions side by side:
```yaml
# Service A uses MQTT v5
mqtt:
  use-mqtt-v5: true

# Service B uses MQTT v3.1.1  
mqtt:
  use-mqtt-v5: false
```

### 3. **Code Updates (Optional)**
To take advantage of MQTT v5 features:

```java
// Old MQTT v3.1.1 way
@Autowired
private MqttService mqttService;

// New MQTT v5 way (automatic injection)
@Autowired
private MqttV5Service mqttV5Service;
```

## 🎯 MQTT v5 Benefits

### 1. **Better Performance**
- **Topic Aliases**: Reduce bandwidth for repeated topic names
- **Flow Control**: Better handling of high-throughput scenarios
- **Session Management**: More efficient connection handling

### 2. **Enhanced Reliability**
- **Detailed Error Codes**: Better debugging and error handling
- **Session Expiry**: Predictable session cleanup
- **Problem Information**: Enhanced troubleshooting

### 3. **Advanced Features**
- **User Properties**: Rich metadata for messages
- **Request-Response**: Built-in RPC pattern support
- **Content Type**: Better message interpretation

### 4. **Future-Proof**
- **Latest Standard**: MQTT v5 is the current standard
- **Broker Support**: All major brokers support MQTT v5
- **Any MQTT v5 Broker**: Full protocol support

## 🛠️ Troubleshooting

### Common Issues

1. **Broker Compatibility**: Ensure your broker supports MQTT v5
2. **Client Library**: MQTT v5 requires Paho v1.2.5+
3. **Configuration**: Check `use-mqtt-v5` setting

### Debug Logging
```yaml
logging:
  level:
    com.h.udemy.java.uservices.infrastructure.mqtt: DEBUG
    org.eclipse.paho: DEBUG
```

### Fallback to MQTT v3.1.1
If you encounter issues, you can always fall back:
```yaml
mqtt:
  use-mqtt-v5: false
```

## 📚 Additional Resources

- [MQTT v5 Specification](https://docs.oasis-open.org/mqtt/mqtt/v5.0/mqtt-v5.0.html)
- [Eclipse Paho MQTT v5 Client](https://www.eclipse.org/paho/)
- [MQTT v5 Specification](https://docs.oasis-open.org/mqtt/mqtt/v5.0/mqtt-v5.0.html)

## 🎉 Ready to Use!

Your MQTT infrastructure library now supports the latest MQTT v5 protocol with all its advanced features while maintaining full backward compatibility. Enjoy the enhanced performance, reliability, and capabilities!
