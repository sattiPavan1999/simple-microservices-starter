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

        stage('Run Parallel Test Suites') {
            parallel {
                
                stage('Frontend Tests') {
                    steps {
                        dir('frontend') {
                            sh 'npm install'
                            sh 'npm test'
                        }
                    }
                }
                
                stage('Products Service Tests') {
                    environment {
                        DATABASE_URL = "postgresql://mockuser:mockpass@localhost:5432/mockdb?schema=public"
                    }
                    steps {
                        dir('products-service') {
                            sh 'npm install'
                            sh 'npx prisma generate'
                            sh 'npm test'
                        }
                    }
                }
                
                stage('Users Service Tests') {
                    environment {
                        DATABASE_URL = "postgresql://mockuser:mockpass@localhost:5432/mockdb?schema=public"
                    }
                    steps {
                        dir('users-service') {
                            sh 'npm install'
                            sh 'npx prisma generate'
                            sh 'npm test'
                        }
                    }
                }
            }
        }
    }
}

