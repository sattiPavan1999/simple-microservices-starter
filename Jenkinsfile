pipeline {
    agent any
    
    // This tells Jenkins to look for your globally configured Node environment
    tools {
        nodejs 'NodeJS 20' // Make sure this matches the exact name inside your Jenkins global tools!
    }

    stages {
        stage('Validate Trigger') {
            steps {
                script {
                    if (env.CHANGE_ID) {
                        echo "Validating PR #${env.CHANGE_ID}"
                        echo "Target branch: ${env.CHANGE_TARGET}"
                    } else {
                        echo "Building branch: ${env.BRANCH_NAME}"
                    }
                }
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('test') {
            environment {
                DATABASE_URL = "postgresql://mockuser:mockpass@localhost:5432/mockdb?schema=public"
            }
            steps {
                dir('frontend') {
                    sh 'npm install && npm test'
                }
                dir('products-service') {
                    sh 'npm install && npx prisma generate && npm test'
                }
                dir('users-service') {
                    sh 'npm install && npx prisma generate && npm test'
                }
            }
        }
    }
}
