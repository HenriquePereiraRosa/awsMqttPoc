# Testcontainers vs JUnit-Only: Why Docker-Based Integration Tests Matter

## Slide 1: Introduction
**Title: Testcontainers vs JUnit-Only Testing**

- Testing strategy decision: Mock vs Real Services
- Focus: Database integration testing with Testcontainers
- Goal: Business rules validation with real database behavior

---

## Slide 2: What Are Testcontainers?

**Testcontainers = Docker-based testing framework**

- **Definition**: Java library that provides lightweight, throwaway instances of databases, message queues, web browsers, etc.
- **How it works**: 
  - Starts Docker containers automatically for tests
  - Provides real database instances (PostgreSQL, MySQL, MongoDB, etc.)
  - Cleans up containers after tests complete
- **Popular databases supported**:
  - PostgreSQL, MySQL, MariaDB
  - MongoDB, Cassandra
  - Redis, Kafka
  - And 100+ more services

---

## Slide 3: Traditional JUnit Approach (Mocked DB)

**Unit Tests with Mocked Database**

### Characteristics:
- ❌ Database is mocked (Mockito, H2 in-memory)
- ❌ No real SQL execution
- ✅ Fast execution
- ✅ No external dependencies

### Limitations:
```java
// Mocked database - doesn't test real SQL behavior
@Mock
private OrderRepository repository;

@Test
void testOrderCreation() {
    when(repository.save(any())).thenReturn(order);
    // This doesn't test:
    // - Real SQL constraints
    // - Database transaction behavior
    // - Foreign key relationships
    // - Performance with real queries
}
```

### Problems:
1. **SQL differences**: PostgreSQL vs MySQL syntax differences not caught
2. **Constraint violations**: Foreign keys, unique constraints not enforced
3. **Transaction behavior**: Rollback behavior different from real DB
4. **Performance**: Query performance cannot be measured

---

## Slide 4: Testcontainers Approach (Real DB)

**Integration Tests with Real Database**

### Characteristics:
- ✅ Real database in Docker container
- ✅ Real SQL execution
- ✅ Real transaction management
- ✅ Real constraints and relationships

### Example:
```java
@SpringBootTest
@ContextConfiguration(initializers = PostgresTestcontainersConfig.Initializer.class)
@ActiveProfiles("integration-tests")
class OrderPaymentSagaIT {
    
    // Tests run against REAL PostgreSQL instance
    // - Real foreign keys enforced
    // - Real transactions
    // - Real SQL performance
    // - Real database errors caught
}
```

### Benefits:
1. **Business rules validated**: DB constraints enforce business rules
2. **Real SQL**: Actual database behavior tested
3. **Performance testing**: Real query performance measured
4. **Cross-database compatibility**: Test against different DB engines

---

## Slide 5: Key Advantages of Testcontainers

### 1. **Real Database Behavior** 🎯
- ✅ Foreign key constraints actually enforced
- ✅ Unique constraints work as expected
- ✅ Transaction rollback behaves correctly
- ✅ Database-specific features (e.g., PostgreSQL JSONB, arrays) tested

### 2. **Business Rules Validation** 💼
```
Example: Order total must match sum of items
- Mocked: Test passes (just returns what you tell it to)
- Testcontainers: Fails if SQL constraint violated (catches real bugs)
```

### 3. **Performance Insights** ⚡
- ✅ Slow queries detected during tests
- ✅ N+1 query problems caught
- ✅ Index usage validated
- ✅ Database connection pooling tested

### 4. **SQL Compatibility** 🔄
- ✅ Database-specific SQL validated
- ✅ Migration scripts tested
- ✅ Cross-database issues caught early

### 5. **Simplified Setup** 🚀
- ✅ No manual database setup needed
- ✅ Containers auto-start and cleanup
- ✅ Consistent environment (same DB version everywhere)
- ✅ Works in CI/CD without infrastructure setup

---

## Slide 6: When to Use Each Approach

### Use Unit Tests (JUnit with Mocks) When:
✅ **Pure business logic** (no database dependency)
```java
@Test
void testPriceCalculation() {
    // No DB needed - pure calculation
    Money total = price.calculateTotal(items);
    assertEquals(expectedTotal, total);
}
```

✅ **Fast feedback loop** (developing algorithm/logic)
✅ **Testing edge cases** quickly
✅ **Testing validation rules** independently
✅ **Legacy code** that's hard to test with real DB

### Use Integration Tests (Testcontainers) When:
✅ **Database-dependent features** (99% of Spring Boot apps)
✅ **Business rules enforced by DB** (constraints, foreign keys)
✅ **Transaction management** (rollback, isolation levels)
✅ **Performance-critical queries**
✅ **Database migrations** (Flyway, Liquibase)
✅ **Real-world scenarios** (e.g., concurrent operations)

---

## Slide 7: Is Integration Testing Always Better?

### ❌ **NO - Both Are Needed!**

### The Testing Pyramid:

```
        /\
       /  \      E2E Tests (Few)
      /____\     - Slow, expensive
     /      \    - Full system tests
    /________\   - Critical user journeys
    
   /          \  Integration Tests (Some)
  /            \ - Testcontainers + Real DB
 /______________\ - Business rules validation
                  - Service integrations
                  
________________  Unit Tests (Many)
                  - Fast, isolated
                  - Pure logic
                  - Edge cases
                  - Quick feedback
```

### Why You Need Both:

1. **Unit Tests** = Fast feedback, catch logic errors quickly
2. **Integration Tests** = Validate real behavior, catch database issues
3. **E2E Tests** = Validate complete user workflows

---

## Slide 8: Database: The Most Critical Component

### Why Database Should NOT Be Mocked:

#### 1. **Business Rules Live in Database** 🏛️
```
Business Rule: "Order total must equal sum of order items"
- DB Constraint: CHECK (total = (SELECT SUM(price) FROM items))
- Mocked Test: ❌ Passes (even if constraint is broken!)
- Testcontainers: ✅ Fails (catches real violation)
```

#### 2. **Performance is Database-Driven** ⚡
```
Slow Query Example:
SELECT * FROM orders WHERE customer_id = ?  -- No index!
- Mocked: Can't detect this
- Testcontainers: Shows slow query in test logs
```

#### 3. **Data Integrity = Business Integrity** 🔒
```
Real-World Bug Caught by Testcontainers:
- Foreign key constraint prevents orphaned records
- Unique constraint prevents duplicate entries
- Not-null constraints enforce required fields
- Mocked tests: All pass! ✅ (but production fails ❌)
```

#### 4. **Transaction Behavior** 💳
```
Real scenario: Payment processing
- Mocked: Transactions "just work"
- Testcontainers: Tests real rollback on error
- Catches: Deadlocks, isolation level issues
```

---

## Slide 9: Real Example: Order Service

### Problem with Mocked Approach:

```java
// ❌ Mocked Test - Passes but doesn't catch real bugs
@Test
void testOrderCreation_Mocked() {
    when(orderRepository.save(order)).thenReturn(order);
    when(orderItemRepository.save(items)).thenReturn(items);
    
    Order result = orderService.createOrder(order);
    assertNotNull(result);
    // ✅ Test passes, but:
    // - What if foreign key constraint is broken?
    // - What if transaction doesn't rollback on error?
    // - What if unique constraint on order number fails?
}
```

### Solution with Testcontainers:

```java
// ✅ Integration Test - Catches real database issues
@SpringBootTest
@ContextConfiguration(initializers = PostgresTestcontainersConfig.Initializer.class)
@ActiveProfiles("integration-tests")
class OrderServiceIT {
    
    @Test
    @Sql(scripts = "classpath:sql/test-setup.sql")
    void testOrderCreation_RealDB() {
        // Tests with REAL database:
        // ✅ Foreign keys enforced
        // ✅ Unique constraints validated
        // ✅ Transactions behave correctly
        // ✅ Performance measured
        Order result = orderService.createOrder(order);
        assertNotNull(result);
    }
}
```

### What Gets Tested:
1. ✅ Real SQL execution
2. ✅ Database constraints
3. ✅ Transaction rollback
4. ✅ Concurrent access (optimistic locking)
5. ✅ Query performance

---

## Slide 10: Performance Comparison

### Execution Time:

| Approach | Setup Time | Test Execution | Total |
|----------|-----------|----------------|-------|
| **Mocked Tests** | 0ms | 50-200ms | Fast ⚡ |
| **Testcontainers** | 2-5s (first time) | 1-3s | Acceptable ✅ |
| | 0-500ms (reused) | | |

### Trade-offs:

**Mocked Tests:**
- ⚡ Fast execution
- ❌ False confidence (passes but production fails)
- ❌ Can't test real behavior

**Testcontainers:**
- ⏱️ Slightly slower (but acceptable)
- ✅ Real behavior validated
- ✅ Catches production issues
- ✅ Worth the time investment!

**Verdict**: The slight performance cost is worth catching real bugs!

---

## Slide 11: CI/CD Integration

### Testcontainers in CI/CD:

✅ **Works seamlessly in Jenkins/GitHub Actions**
- Docker available in CI environments
- Containers start automatically
- No manual database setup needed

✅ **Consistent Testing Environment**
- Same DB version in local dev and CI
- No "works on my machine" issues
- Reproducible test results

✅ **Parallel Execution**
- Multiple containers can run simultaneously
- Tests can run in parallel safely

### Example (Jenkins/GitHub Actions):
```yaml
# Docker is required (usually available)
services:
  docker:
    image: docker:dind
```

---

## Slide 12: Best Practices

### ✅ DO:

1. **Use Testcontainers for database-dependent tests**
   - Repository tests
   - Service tests with DB
   - Transaction tests
   - Performance-critical queries

2. **Keep containers lightweight**
   - Use `alpine` images when possible
   - Reuse containers (`withReuse(true)`)
   - Clean up properly

3. **Isolate test data**
   - Use `@Sql` scripts for setup/cleanup
   - Each test uses separate data
   - Transactions rollback between tests

4. **Mock external services**
   - Still mock REST APIs
   - Still mock message queues (or use Testcontainers)
   - But don't mock the database!

### ❌ DON'T:

1. **Don't mock the database for business-critical features**
2. **Don't run integration tests for pure logic**
3. **Don't forget to cleanup test data**
4. **Don't use production-like data volumes**

---

## Slide 13: Migration Strategy

### From Mocked to Testcontainers:

**Step 1: Identify Critical Tests**
- List database-dependent features
- Prioritize business-critical paths
- Identify performance-sensitive queries

**Step 2: Add Testcontainers Setup**
```java
@SpringBootTest
@ContextConfiguration(initializers = PostgresTestcontainersConfig.Initializer.class)
@ActiveProfiles("integration-tests")
```

**Step 3: Migrate Tests Gradually**
- Start with one service/feature
- Keep mocked tests for pure logic
- Add integration tests for DB features

**Step 4: Run Both in CI/CD**
- Unit tests: Fast feedback
- Integration tests: Real validation

---

## Slide 14: Conclusion

### Key Takeaways:

1. **Database = Critical Component** 🎯
   - Business rules enforced by DB
   - Performance driven by queries
   - Don't mock it!

2. **Testcontainers = Real Testing** ✅
   - Validates actual behavior
   - Catches production issues early
   - Worth the slight performance cost

3. **Balance is Key** ⚖️
   - Unit tests for pure logic (fast feedback)
   - Integration tests for DB features (real validation)
   - Both have their place!

4. **Real-World Impact** 💼
   - Prevents production bugs
   - Validates business rules
   - Measures real performance
   - Builds confidence in deployments

---

## Slide 15: Q&A

### Common Questions:

**Q: Aren't Testcontainers slow?**
A: Slightly slower, but the value of catching real bugs outweighs the cost.

**Q: Should I replace ALL unit tests?**
A: No! Use unit tests for pure logic, integration tests for DB features.

**Q: What about test data management?**
A: Use `@Sql` scripts and transaction rollback for isolation.

**Q: Can I use Testcontainers in CI/CD?**
A: Yes! Docker is available in most CI environments.

**Q: What if Docker isn't available?**
A: Use mocks for unit tests, but try to get Docker for integration tests.

---

## Slide 16: Resources

### Learn More:

- **Testcontainers**: https://www.testcontainers.org/
- **Spring Boot Testing**: https://spring.io/guides/gs/testing-web/
- **Docker**: https://www.docker.com/

### Your Project:
- Current setup: Testcontainers for PostgreSQL + Kafka
- Location: `apis/order-service/order-container/src/test/...`
- Example: `OrderPaymentSagaIT.java`

---

**Thank You!**

*Questions? Let's discuss!*


