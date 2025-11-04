
# Professional Local Jenkins CI/CD Setup Plan

## 🎯 Goal

Set up Jenkins locally as a full professional CI/CD solution for your AWS MQTT POC project, with comprehensive pipelines for build, test, and deployment.

---

## 📋 Project Overview

Your project structure:
- **Parent POM**: `apis/pom.xml`
- **Modules**:
  - `common` (common-domain, common-infra, test-utils)
  - `infrastructure` (kafka, mqtt, outbox, saga)
  - `order-service` (domain, application, dataaccess, messaging, container)
- **Tech Stack**: Java 21, Spring Boot 3.5.4, Maven, Docker, Testcontainers
- **Infrastructure**: Terraform for AWS resources

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Jenkins (Local)                       │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Pipeline   │  │   Pipeline   │  │   Pipeline   │  │
│  │   Builder    │  │   Tester     │  │   Deployer   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         │                  │                  │          │
│         └──────────────────┼──────────────────┘          │
│                            │                             │
├────────────────────────────┼─────────────────────────────┤
│         │                  │                  │          │
│    Docker Engine       Maven/Java 21    Terraform        │
│                            │                             │
└────────────────────────────┼─────────────────────────────┘
                             │
                    ┌────────┴────────┐
                    │   Your Repo     │
                    └─────────────────┘
```

---

## 📦 Phase 1: Jenkins Installation & Setup

### Step 1.1: Install Jenkins Locally

**Option A: Docker (Recommended)**
```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts-jdk21
```

**Option B: Native Installation**
- Download Jenkins LTS from https://www.jenkins.io/download/
- Install with Java 21

### Step 1.2: Initial Configuration

1. **Access**: `http://localhost:8080`
2. **Get password**: `docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword`
3. **Install suggested plugins**:
   - Git
   - Pipeline
   - Blue Ocean (optional, nice UI)
   - Maven Integration
   - Docker Pipeline
   - HTML Publisher (for reports)
   - JUnit (test results)
   - JaCoCo (coverage)
   - Warnings Next Generation

### Step 1.3: Configure Tools

**Manage Jenkins** → **Global Tool Configuration**:

- **JDK**: 
  - Name: `jdk-21`
  - JAVA_HOME: `/usr/lib/jvm/java-21-openjdk` (or your Java 21 path)
  
- **Maven**:
  - Name: `maven-3.9`
  - Version: `3.9.5` (auto-install)
  
- **Docker**:
  - Name: `docker`
  - Docker Installations: Docker (from Docker installation)

---

## 🔧 Phase 2: Pipeline Structure

### Structure Overview

```
Jenkinsfile (Root)                    # Main pipeline
├── build.groovy                      # Build stage logic
├── test.groovy                       # Test stage logic
├── report.groovy                     # Report generation
├── deploy.groovy                     # Deployment logic
└── shared/
    ├── changeDetection.groovy        # Change detection logic
    ├── notifications.groovy          # Notification logic
    └── cleanup.groovy                # Cleanup logic
```

### Pipeline Stages:

1. **Checkout** → Clone repository
2. **Change Detection** → Detect which modules changed
3. **Build** → Compile all modules (or changed + dependencies)
4. **Unit Tests** → Run unit tests
5. **Integration Tests** → Run IT tests (with Testcontainers)
6. **Code Quality** → Code coverage, static analysis
7. **Package** → Create JARs
8. **Reports** → Generate test/coverage reports
9. **Deploy** → (Optional) Deploy to environments
10. **Archive** → Archive artifacts

---

## 📝 Phase 3: Create Jenkinsfile

### Main Jenkinsfile (Declarative Pipeline)

Create `Jenkinsfile` in root:

```groovy
pipeline {
    agent any
    
    tools {
        jdk 'jdk-21'
        maven 'maven-3.9'
    }
    
    environment {
        PROJECT_ROOT = "${WORKSPACE}"
        MAVEN_OPTS = '-Xmx2048m -XX:MaxPermSize=512m'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Change Detection') {
            steps {
                script {
                    // Detect changed modules
                    def changes = detectChanges()
                    env.CHANGED_MODULES = changes.join(',')
                    echo "Changed modules: ${env.CHANGED_MODULES}"
                }
            }
        }
        
        stage('Build') {
            steps {
                dir('apis') {
                    script {
                        sh 'mvn clean install -DskipTests'
                    }
                }
            }
        }
        
        stage('Unit Tests') {
            steps {
                dir('apis') {
                    script {
                        sh 'mvn test'
                    }
                }
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('Integration Tests') {
            steps {
                dir('apis') {
                    script {
                        sh 'mvn verify -DskipTests=false -Pintegration-tests'
                    }
                }
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('Code Coverage') {
            steps {
                dir('apis') {
                    script {
                        sh 'mvn verify'
                    }
                }
            }
            post {
                always {
                    jacoco(
                        execPattern: '**/target/jacoco.exec',
                        classPattern: '**/target/classes',
                        sourcePattern: '**/src/main/java',
                        exclusionPattern: '**/target/generated-sources/**'
                    )
                }
            }
        }
        
        stage('Package') {
            steps {
                dir('apis') {
                    script {
                        sh 'mvn package -DskipTests'
                    }
                }
            }
        }
        
        stage('Generate Reports') {
            steps {
                dir('apis') {
                    script {
                        sh 'mvn surefire-report:report jacoco:report'
                    }
                }
                publishHTML([
                    reportName: 'Test Report',
                    reportDir: 'apis/target/site/surefire-report.html',
                    reportFiles: 'surefire-report.html',
                    keepAll: true
                ])
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}

def detectChanges() {
    def changedFiles = sh(
        script: 'git diff --name-only HEAD~1 HEAD',
        returnStdout: true
    ).trim().split('\n')
    
    def modules = []
    changedFiles.each { file ->
        if (file.contains('apis/order-service')) {
            modules.add('order-service')
        } else if (file.contains('apis/common')) {
            modules.add('common')
        } else if (file.contains('apis/infrastructure')) {
            modules.add('infrastructure')
        }
    }
    
    return modules.unique()
}
```

---

## 🎨 Phase 4: Advanced Features

### 4.1: Multi-Branch Pipeline

Create a **Multibranch Pipeline** job:
- **Branch Sources**: Git → Your repo
- **Behaviors**: Discover branches, Discover PRs
- **Build Configuration**: Jenkinsfile

### 4.2: Pipeline Libraries

Create shared library for reusable functions:
```
vars/
├── buildModule.groovy
├── testModule.groovy
├── deployModule.groovy
└── notifySlack.groovy
```

### 4.3: Parallel Execution

Run tests in parallel for faster builds:
```groovy
stage('Parallel Tests') {
    parallel {
        stage('Unit Tests') {
            steps {
                sh 'mvn test'
            }
        }
        stage('Integration Tests') {
            steps {
                sh 'mvn verify -Pintegration-tests'
            }
        }
    }
}
```

### 4.4: Docker Integration

Build Docker images for services:
```groovy
stage('Build Docker Image') {
    steps {
        script {
            docker.build("awsmqttpoc/order-service:${env.BUILD_NUMBER}")
        }
    }
}
```

### 4.5: Terraform Integration

Deploy infrastructure:
```groovy
stage('Deploy Infrastructure') {
    steps {
        dir('apis/infrastructure/iac/terraform/services/mqtt') {
            sh 'terraform init'
            sh 'terraform plan'
            sh 'terraform apply -auto-approve'
        }
    }
}
```

---

## 📊 Phase 5: Reporting & Monitoring

### Test Results
- **JUnit Plugin**: Automatically publishes test results
- **HTML Publisher**: Shows test reports
- **Warnings NG**: Code quality warnings

### Code Coverage
- **JaCoCo Plugin**: Code coverage reports
- **Coverage Trend**: Historical coverage data

### Build History
- **Build History Plugin**: Visual build trends
- **Build Time Trend**: Performance metrics

---

## 🔐 Phase 6: Security & Best Practices

### Credentials Management
- Store AWS credentials in Jenkins Credentials
- Use Credential Binding in pipelines
- Never hardcode secrets

### Pipeline Security
- Use `@Library` for shared libraries
- Scan for vulnerabilities (OWASP plugin)
- Code signing for artifacts

---

## 🚀 Phase 7: Deployment Pipeline

### Environment Promotion
```groovy
stage('Deploy to Dev') {
    steps {
        deployToEnvironment('dev')
    }
}

stage('Deploy to Staging') {
    when {
        branch 'release/**'
    }
    steps {
        input message: 'Deploy to Staging?'
        deployToEnvironment('staging')
    }
}

stage('Deploy to Prod') {
    when {
        branch 'main'
    }
    steps {
        input message: 'Deploy to Production?'
        deployToEnvironment('prod')
    }
}
```

---

## 📋 Implementation Checklist

- [ ] Install Jenkins locally (Docker or native)
- [ ] Configure global tools (JDK, Maven, Docker)
- [ ] Install required plugins
- [ ] Create main `Jenkinsfile`
- [ ] Create Multibranch Pipeline job
- [ ] Test build pipeline
- [ ] Test test pipeline
- [ ] Configure test reports
- [ ] Configure code coverage
- [ ] Set up notifications (optional)
- [ ] Create deployment pipeline (optional)
- [ ] Document pipeline usage

---

## 📚 Next Steps

1. **I'll create the `Jenkinsfile`** with all stages
2. **Create shared library** for reusable functions
3. **Create job configuration** instructions
4. **Create deployment pipeline** templates

Would you like me to create the complete `Jenkinsfile` now?

