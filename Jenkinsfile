pipeline {
  agent any

  environment {
    DOCKER_HUB_USER      = "shreepalsingh"
    BACKEND_IMAGE        = "${DOCKER_HUB_USER}/crud-dd-task-mean-app-backend"
    FRONTEND_IMAGE       = "${DOCKER_HUB_USER}/crud-dd-task-mean-app-frontend"
    SONAR_URL            = "http://44.223.94.9:9000"
    GIT_REPO_NAME        = "Project-MEAN-Stack-Deployment"
    GIT_USER_NAME        = "shreepal811"
  }

  stages {

    stage('Checkout') {
      steps {
        git branch: 'main', url: 'https://github.com/Shreepal811/Project-MEAN-Stack-Deployment.git'
      }
    }

    stage('Increment Version') {
      steps {
        sh 'git fetch origin release-state'
        sh 'git checkout origin/release-state -- version.txt'
        script {
          def version = readFile('version.txt').trim()
          echo "Current version: ${version}"

          def parts = version.tokenize('.')
          def major = parts[0].toInteger()
          def minor = parts[1].toInteger()
          def patch = parts[2].toInteger()

          patch += 1

          def newVersion = "${major}.${minor}.${patch}"
          echo "New version: ${newVersion}"

          writeFile file: 'version.txt', text: newVersion

          env.APP_VERSION = newVersion
        }
      }
    }

    stage('Backend Test') {
      steps {
        sh '''
          cd backend
          npm install
          npm test
        '''
      }
    }

    stage('Frontend Test') {
        steps {
            sh 'echo "Frontend tests skipped" && exit 0'
        }
    }

   stage('Static Code Analysis') {
  steps {
    withSonarQubeEnv('SonarQube') {
      withCredentials([string(credentialsId: 'sonarqube', variable: 'SONAR_AUTH_TOKEN')]) {
        sh '''
          /opt/sonar-scanner/bin/sonar-scanner \
            -Dsonar.projectKey=mean-app \
            -Dsonar.sources=backend,frontend/src \
            -Dsonar.exclusions=**/node_modules/**,**/dist/** \
            -Dsonar.host.url=${SONAR_URL} \
            -Dsonar.login=${SONAR_AUTH_TOKEN}
        '''
      }
    }
  }
}

    stage('Quality Gate') {
      steps {
        timeout(time: 7, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }

    stage('Build and Push Docker Images') {
      steps {
        script {
          sh "docker build -t ${BACKEND_IMAGE}:${APP_VERSION} ./backend"
          sh "docker build -t ${FRONTEND_IMAGE}:${APP_VERSION} ./frontend"

          docker.withRegistry('https://index.docker.io/v1/', 'docker-cred') {
            docker.image("${BACKEND_IMAGE}:${APP_VERSION}").push()
            docker.image("${FRONTEND_IMAGE}:${APP_VERSION}").push()
          }
        }
      }
    }

    stage('Update Deployment Files') {
      steps {
        sh 'git checkout origin/release-state -- app-manifests/'
        withCredentials([string(credentialsId: 'github', variable: 'GITHUB_TOKEN')]) {
          sh '''
            git config --global user.email "shreepalsingh811@gmail.com"
            git config --global user.name "Shreepal Singh"
            git remote set-url origin https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME}

            sed -i "s|${BACKEND_IMAGE}:.*|${BACKEND_IMAGE}:${APP_VERSION}|g"  app-manifests/backend-deployment.yml
            sed -i "s|${FRONTEND_IMAGE}:.*|${FRONTEND_IMAGE}:${APP_VERSION}|g" app-manifests/frontend-deployment.yml

             # clone release-state into separate temp folder
        rm -rf /tmp/release-state-repo
        git clone -b release-state https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} /tmp/release-state-repo

        # copy only 3 files into temp folder
        cp version.txt /tmp/release-state-repo/
        cp app-manifests/backend-deployment.yml /tmp/release-state-repo/app-manifests/
        cp app-manifests/frontend-deployment.yml /tmp/release-state-repo/app-manifests/

        # commit and push from temp folder
        cd /tmp/release-state-repo
        git add version.txt app-manifests/
        git commit -m "Release version ${APP_VERSION}"
        git push origin release-state
          '''
        }
      }
    }

  }  

  post {
    success {
      echo "✅ Version ${APP_VERSION} deployed successfully!"
    }
    failure {
      echo "❌ Pipeline Failed at version ${APP_VERSION}"
    }
    always {
      sh "docker logout"
    }
  }

}  
