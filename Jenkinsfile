pipeline {
  agent any

  environment {
    IMAGE_PREFIX = 'nt548'
    KUBECONFIG = credentials('kubeconfig')
    SONARQUBE_ENV = 'sonarqube'
  }

  stages {
    stage('Install and test') {
      parallel {
        stage('api-gateway') {
          steps {
            sh '''
              cd microservices/api-gateway
              python3 -m venv .venv
              . .venv/bin/activate
              pip install -r requirements.txt
              pytest
            '''
          }
        }
        stage('orders-service') {
          steps {
            sh '''
              cd microservices/orders-service
              python3 -m venv .venv
              . .venv/bin/activate
              pip install -r requirements.txt
              pytest
            '''
          }
        }
      }
    }

    stage('SonarQube analysis') {
      steps {
        withSonarQubeEnv("${SONARQUBE_ENV}") {
          sh 'sonar-scanner'
        }
      }
    }

    stage('Build images') {
      steps {
        sh '''
          docker build -t ${IMAGE_PREFIX}/api-gateway:${BUILD_NUMBER} microservices/api-gateway
          docker build -t ${IMAGE_PREFIX}/orders-service:${BUILD_NUMBER} microservices/orders-service
          docker tag ${IMAGE_PREFIX}/api-gateway:${BUILD_NUMBER} ${IMAGE_PREFIX}/api-gateway:latest
          docker tag ${IMAGE_PREFIX}/orders-service:${BUILD_NUMBER} ${IMAGE_PREFIX}/orders-service:latest
        '''
      }
    }

    stage('Security scan') {
      steps {
        sh '''
          docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --exit-code 0 --severity HIGH,CRITICAL ${IMAGE_PREFIX}/api-gateway:${BUILD_NUMBER}
          docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --exit-code 0 --severity HIGH,CRITICAL ${IMAGE_PREFIX}/orders-service:${BUILD_NUMBER}
        '''
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        sh '''
          if command -v kind >/dev/null 2>&1 && kind get clusters | grep -q '^nt548-lab02$'; then
            kind load docker-image ${IMAGE_PREFIX}/api-gateway:${BUILD_NUMBER} --name nt548-lab02
            kind load docker-image ${IMAGE_PREFIX}/orders-service:${BUILD_NUMBER} --name nt548-lab02
          fi
          kubectl apply -f k8s/namespace.yaml
          kubectl apply -f k8s/orders-service.yaml
          kubectl apply -f k8s/api-gateway.yaml
          kubectl -n nt548-lab02 set image deployment/api-gateway api-gateway=${IMAGE_PREFIX}/api-gateway:${BUILD_NUMBER}
          kubectl -n nt548-lab02 set image deployment/orders-service orders-service=${IMAGE_PREFIX}/orders-service:${BUILD_NUMBER}
          kubectl -n nt548-lab02 rollout status deployment/api-gateway
          kubectl -n nt548-lab02 rollout status deployment/orders-service
        '''
      }
    }
  }
}
