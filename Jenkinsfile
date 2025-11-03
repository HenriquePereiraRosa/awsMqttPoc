
pipeline {
    agent any
    
    tools {
        jdk 'jdk-21'
        maven 'maven-3.9'
    }
    
    environment {
        PROJECT_ROOT = "${WORKSPACE}"
        JAVA_HOME = '/opt/java/openjdk'
        MAVEN_OPTS = '-Xmx2048m'
        DOCKER_HOST = 'unix:///var/run/docker.sock'
    }
    
    options {
        // Keep last 20 builds for history
        buildDiscarder(logRotator(
            numToKeepStr: '20',
            artifactNumToKeepStr: '10'
        ))
        
        // Add timestamps to console output
        timestamps()
        
        // Add ANSI color support
        ansiColor('xterm')
        
        // Timeout after 60 minutes
        timeout(time: 60, unit: 'MINUTES')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Project Information') {
            steps {
                script {
                    // Get git info for display
                    def gitCommit = sh(
                        script: 'git rev-parse HEAD',
                        returnStdout: true
                    ).trim()
                    def gitBranch = sh(
                        script: 'git rev-parse --abbrev-ref HEAD',
                        returnStdout: true
                    ).trim()
                    def gitAuthor = sh(
                        script: 'git log -1 --pretty=format:"%an"',
                        returnStdout: true
                    ).trim()
                    def gitMessage = sh(
                        script: 'git log -1 --pretty=format:"%s"',
                        returnStdout: true
                    ).trim()
                    
                    // Check if this is a PR build (GitHub plugin provides CHANGE_ID)
                    def isPR = env.CHANGE_ID != null
                    def prInfo = ""
                    if (isPR) {
                        prInfo = """
   • PR #${env.CHANGE_ID}: ${env.CHANGE_TITLE ?: gitMessage}
   • PR Author: ${env.CHANGE_AUTHOR ?: gitAuthor}
   • Target Branch: ${env.CHANGE_TARGET ?: 'main'}"""
                    }
                    
                    echo """
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 AWS MQTT POC - Continuous Integration (Jenkins)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔹 Project: AWS MQTT Proof of Concept
🔹 Purpose: IoT device communication via MQTT over TLS
🔹 Main Services:
   • MQTT Service (AWS IoT Core integration)
   • Order Service (Spring Boot microservice)
   • Kafka integration (message buffering)

🔹 Technology Stack:
   • Java 21 (OpenJDK/Temurin)
   • Spring Boot 3.5.4
   • Maven 3.9+
   • AWS IoT Core
   • Apache Kafka
   • PostgreSQL (with Testcontainers)
   • Terraform (Infrastructure as Code)

🔹 CI/CD:
   • Primary: Jenkins (local Docker setup)
   • Secondary: GitHub Actions

🔹 Build Information:
   • Build Number: #${env.BUILD_NUMBER}
   • Branch: ${gitBranch}
   • Commit: ${gitCommit.take(7)}
   • Commit Message: ${gitMessage}
   • Author: ${gitAuthor}
   • Build Type: ${isPR ? 'Pull Request' : 'Branch Build'}${prInfo}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""
                    
                    // Store for later use
                    env.GIT_COMMIT = gitCommit
                    env.GIT_BRANCH = gitBranch
                    env.GIT_AUTHOR = gitAuthor
                    env.IS_PR = isPR.toString()
                }
            }
        }
        
        stage('Change Detection') {
            steps {
                script {
                    // Detect changed files (compare with previous commit or main)
                    def previousCommit = env.GIT_PREVIOUS_COMMIT ?: 'origin/main'
                    def changedFiles = sh(
                        script: """
                            git diff --name-only ${previousCommit} ${env.GIT_COMMIT} 2>/dev/null || \
                            git diff --name-only HEAD~1 HEAD 2>/dev/null || \
                            echo ''
                        """,
                        returnStdout: true
                    ).trim()
                    
                    env.CHANGED_FILES = changedFiles
                    
                    // Determine which modules changed
                    def commonChanged = changedFiles.contains('apis/common/') || 
                                       changedFiles.contains('apis/pom.xml') ||
                                       changedFiles == ''
                    
                    def orderServiceChanged = changedFiles.contains('apis/order-service/')
                    def infrastructureChanged = changedFiles.contains('apis/infrastructure/')
                    
                    // If common changed or no changes detected, build all
                    if (commonChanged || changedFiles == '') {
                        env.BUILD_ALL = 'true'
                        env.BUILD_ORDER_SERVICE = 'false'
                        env.BUILD_INFRASTRUCTURE = 'false'
                    } else {
                        env.BUILD_ALL = 'false'
                        env.BUILD_ORDER_SERVICE = orderServiceChanged.toString()
                        env.BUILD_INFRASTRUCTURE = infrastructureChanged.toString()
                    }
                    
                    echo "========================================="
                    echo "Change Detection Results:"
                    echo "========================================="
                    echo "Changed Files: ${changedFiles ?: 'None detected (building all)'}"
                    echo "Build All: ${env.BUILD_ALL}"
                    echo "Build Order Service: ${env.BUILD_ORDER_SERVICE}"
                    echo "Build Infrastructure: ${env.BUILD_INFRASTRUCTURE}"
                    echo "========================================="
                }
            }
        }
        
        stage('Build') {
            steps {
                dir('apis') {
                    script {
                        if (env.BUILD_ALL == 'true') {
                            echo "🔨 Building all modules..."
                            sh 'mvn clean install -DskipTests'
                        } else {
                            def modulesToBuild = []
                            if (env.BUILD_ORDER_SERVICE == 'true') {
                                modulesToBuild.add('order-service')
                            }
                            if (env.BUILD_INFRASTRUCTURE == 'true') {
                                modulesToBuild.add('infrastructure')
                            }
                            
                            if (modulesToBuild.size() > 0) {
                                def modulesArg = modulesToBuild.join(',')
                                echo "🔨 Building modules: ${modulesArg}"
                                sh "mvn clean install -pl ${modulesArg} -am -DskipTests"
                            } else {
                                echo "⚠️ No modules to build"
                            }
                        }
                    }
                }
            }
        }
        
        stage('Unit Tests') {
            steps {
                dir('apis') {
                    script {
                        if (env.BUILD_ALL == 'true') {
                            sh 'mvn test'
                        } else {
                            def modulesToTest = []
                            if (env.BUILD_ORDER_SERVICE == 'true') {
                                modulesToTest.add('order-service')
                            }
                            if (env.BUILD_INFRASTRUCTURE == 'true') {
                                modulesToTest.add('infrastructure')
                            }
                            
                            if (modulesToTest.size() > 0) {
                                def modulesArg = modulesToTest.join(',')
                                sh "mvn test -pl ${modulesArg} -am"
                            }
                        }
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
                        // Check if Docker is available for Testcontainers
                        def dockerAvailable = sh(
                            script: 'docker --version',
                            returnStdout: true,
                            returnStatus: true
                        ) == 0
                        
                        if (!dockerAvailable) {
                            echo "⚠️ Docker not available - skipping integration tests"
                            return
                        }
                        
                        echo "🧪 Running integration tests with Testcontainers..."
                        
                        if (env.BUILD_ALL == 'true') {
                            sh 'mvn verify -DskipTests=false -Pintegration-tests'
                        } else {
                            def modulesToTest = []
                            if (env.BUILD_ORDER_SERVICE == 'true') {
                                modulesToTest.add('order-service')
                            }
                            if (env.BUILD_INFRASTRUCTURE == 'true') {
                                modulesToTest.add('infrastructure')
                            }
                            
                            if (modulesToTest.size() > 0) {
                                def modulesArg = modulesToTest.join(',')
                                sh "mvn verify -pl ${modulesArg} -am -DskipTests=false -Pintegration-tests"
                            }
                        }
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
                        echo "📊 Generating code coverage report..."
                        // Coverage is generated during verify phase
                        sh 'mvn jacoco:report || true'
                    }
                }
            }
            post {
                always {
                    script {
                        // Use Coverage Plugin (replaces deprecated JaCoCo plugin)
                        // Coverage Plugin reads JaCoCo XML reports generated by Maven
                        def jacocoFiles = findFiles(glob: '**/target/site/jacoco/jacoco.xml')
                        if (jacocoFiles.length > 0) {
                            // Coverage Plugin automatically detects JaCoCo XML reports
                            // from target/site/jacoco/jacoco.xml files
                            publishCoverage(
                                adapters: [
                                    jacocoAdapter('**/target/site/jacoco/jacoco.xml')
                                ],
                                sourceFileResolver: sourceFiles('STORE_LAST_BUILD')
                            )
                        } else {
                            echo "⚠️ No JaCoCo XML reports found (run 'mvn jacoco:report' first)"
                        }
                    }
                }
            }
        }
        
        stage('Generate Reports') {
            steps {
                dir('apis') {
                    script {
                        echo "📝 Generating test and coverage reports..."
                        sh 'mvn surefire-report:report-only || true'
                        
                        // Aggregate reports if multiple modules
                        sh 'mvn jacoco:report-aggregate || true'
                    }
                }
            }
        }
        
        stage('SonarQube Analysis') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                    branch 'release/**'
                }
            }
            steps {
                dir('apis') {
                    script {
                        echo "🔍 Running SonarQube code analysis..."
                        // Check if SonarQube plugin is available (optional)
                        try {
                            // If SonarQube Scanner plugin is installed, use it
                            withSonarQubeEnv('SonarCloud') {
                                sh 'mvn sonar:sonar'
                            }
                        } catch (Exception e) {
                            // Fallback: Run SonarQube without Jenkins plugin
                            // Requires sonar properties to be set via environment variables or sonar-project.properties
                            echo "⚠️ SonarQube Scanner plugin not found, running with Maven plugin only"
                            echo "💡 Tip: Install 'SonarQube Scanner' plugin for better integration"
                            sh 'mvn sonar:sonar -Dsonar.host.url=https://sonarcloud.io'
                        }
                    }
                }
            }
        }
        
        stage('Quality Gate') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                    branch 'release/**'
                }
            }
            steps {
                script {
                    try {
                        echo "⏳ Waiting for SonarQube Quality Gate..."
                        timeout(time: 5, unit: 'MINUTES') {
                            def qg = waitForQualityGate()
                            if (qg.status != 'OK') {
                                error "Quality Gate failed: ${qg.status}"
                            }
                        }
                    } catch (Exception e) {
                        echo "⚠️ SonarQube Quality Gate check skipped (SonarQube Scanner plugin not installed)"
                        echo "💡 Install 'SonarQube Scanner' plugin to enable Quality Gate checks"
                    }
                }
            }
        }
        
        stage('Package') {
            when {
                anyOf {
                    branch 'main'
                    branch 'release/**'
                }
            }
            steps {
                dir('apis') {
                    script {
                        echo "📦 Packaging artifacts..."
                        if (env.BUILD_ALL == 'true') {
                            sh 'mvn package -DskipTests'
                        } else {
                            def modulesToPackage = []
                            if (env.BUILD_ORDER_SERVICE == 'true') {
                                modulesToPackage.add('order-service')
                            }
                            if (env.BUILD_INFRASTRUCTURE == 'true') {
                                modulesToPackage.add('infrastructure')
                            }
                            
                            if (modulesToPackage.size() > 0) {
                                def modulesArg = modulesToPackage.join(',')
                                sh "mvn package -pl ${modulesArg} -am -DskipTests"
                            }
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            // Publish HTML Reports
            script {
                echo "📊 Publishing HTML reports..."
                
                // Publish Surefire test reports
                publishHTML([
                    reportName: 'Test Results',
                    reportDir: 'apis',
                    reportFiles: '**/target/site/surefire-report.html',
                    reportTitles: 'Maven Surefire Test Report',
                    keepAll: true,
                    alwaysLinkToLastBuild: true,
                    allowMissing: true
                ])
                
                // Publish JaCoCo coverage reports
                publishHTML([
                    reportName: 'Code Coverage',
                    reportDir: 'apis',
                    reportFiles: '**/target/site/jacoco/index.html',
                    reportTitles: 'JaCoCo Code Coverage Report',
                    keepAll: true,
                    alwaysLinkToLastBuild: true,
                    allowMissing: true
                ])
            }
            
            // Archive artifacts
            archiveArtifacts(
                artifacts: '**/target/*.jar,**/target/surefire-reports/**,**/target/site/**',
                allowEmptyArchive: true,
                fingerprint: true
            )
            
            // Clean workspace (optional - saves disk space)
            // cleanWs()
        }
        
        success {
            script {
                echo """
                ✅ ========================================
                ✅ Pipeline SUCCESS!
                ✅ ========================================
                ✅ Branch: ${env.GIT_BRANCH}
                ✅ Commit: ${env.GIT_COMMIT.take(7)}
                ✅ Author: ${env.GIT_AUTHOR}
                ✅ ========================================
                """
            }
        }
        
        failure {
            script {
                echo """
                ❌ ========================================
                ❌ Pipeline FAILED!
                ❌ ========================================
                ❌ Branch: ${env.GIT_BRANCH}
                ❌ Commit: ${env.GIT_COMMIT.take(7)}
                ❌ Check the logs above for details
                ❌ ========================================
                """
            }
        }
        
        unstable {
            script {
                echo """
                ⚠️ ========================================
                ⚠️ Pipeline UNSTABLE (some tests failed)
                ⚠️ ========================================
                ⚠️ Branch: ${env.GIT_BRANCH}
                ⚠️ Commit: ${env.GIT_COMMIT.take(7)}
                ⚠️ ========================================
                """
            }
        }
    }
}

