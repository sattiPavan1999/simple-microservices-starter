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
            steps {
                // Testing Frontend (Works perfectly)
                dir('frontend') {
                    sh 'npm install'
                    sh 'npm test'
                }
                
                // Testing Products Service
                dir('products-service') {
                    sh 'npm install'
                    sh 'npx prisma generate' // Generates the missing client artifacts
                    sh 'npm test'
                }
                
                // Testing Users Service
                dir('users-service') {
                    sh 'npm install'
                    sh 'npx prisma generate' // Generates the missing client artifacts
                    sh 'npm test'
                }
            }
        }
    }
}
