pipeline {
    agent any
    tools {
        jdk 'jdk-21'
        maven 'maven-3.9'
    }
    stages {
        stage('Test Tools') {
            steps {
                sh '''
                    export JAVA_HOME=/opt/java/openjdk
                    echo "=== Java Version ==="
                    java -version
                    echo ""
                    echo "=== JAVA_HOME ==="
                    echo "JAVA_HOME=$JAVA_HOME"
                    echo ""
                    echo "=== Maven Version ==="
                    mvn -version
                '''
            }
        }
    }
}

