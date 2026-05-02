pipeline {
    agent { label 'kaniko' }

    parameters {
        choice(name: 'DEPLOY_ENV', choices: ['dev', 'prod'], description: 'Оберіть середовище для деплою')
    }

    environment {
        IMAGE_TAG = "v-${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout & Load Config') {
            steps {
                checkout scm
                script {
                    def configFile = "ci.${params.DEPLOY_ENV}.properties"
                    def props = readProperties file: configFile

                    env.GITHUB_REPO = props.GITHUB_REPO
                    env.REPO_NAME = props.REPO_NAME

                    if (params.DEPLOY_ENV == 'prod') {
                        container('aws-cli') {
                            def accountId = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
                            env.ECR_REGISTRY = "${accountId}.dkr.ecr.${props.AWS_REGION}.amazonaws.com"
                            env.KANIKO_EXTRA_ARGS = "" // AWS Prod: безпечний HTTPS
                        }

                        env.CLUSTER_NAME = props.CLUSTER_NAME
                        env.AWS_LBC_ROLE_ARN = props.AWS_LBC_ROLE_ARN
                        env.ESO_ROLE_ARN = props.ESO_ROLE_ARN
                        env.KARPENTER_ROLE_ARN = props.KARPENTER_ROLE_ARN

                    } else {
                        env.ECR_REGISTRY = props.ECR_REGISTRY
                        env.KANIKO_EXTRA_ARGS = "--insecure --insecure-pull" // LocalStack: вимикаємо TLS для HTTP
                    }
                }
                echo "ECR Address: ${env.ECR_REGISTRY}"
            }
        }

        stage('Build & Push (Kaniko)') {
            steps {
                container('kaniko') {
                    sh '''
                    /kaniko/executor \
                      --context $(pwd) \
                      --dockerfile $(pwd)/Dockerfile \
                      --destination ${ECR_REGISTRY}/${REPO_NAME}:${IMAGE_TAG} \
                      --destination ${ECR_REGISTRY}/${REPO_NAME}:latest \
                      --cache=true \
                      ${KANIKO_EXTRA_ARGS}
                    '''
                }
            }
        }

        stage('Update GitOps Repo (ArgoCD)') {
            steps {
                container('git') {
                    script {
                        sh "sed -i 's/tag: .*/tag: \"${IMAGE_TAG}\"/' charts/django-app/values.yaml"

                        if (params.DEPLOY_ENV == 'prod') {
                            sh """
                                # AWS Load Balancer Controller
                                sed -i "s/REPLACE_CLUSTER_NAME/${env.CLUSTER_NAME}/g" k8s-addons/aws-load-balancer-controller.yaml
                                sed -i "s|REPLACE_LBC_ROLE_ARN|${env.AWS_LBC_ROLE_ARN}|g" k8s-addons/aws-load-balancer-controller.yaml

                                # External Secrets Operator
                                sed -i "s|REPLACE_ESO_ROLE_ARN|${env.ESO_ROLE_ARN}|g" k8s-addons/external-secrets.yaml

                                # Karpenter
                                sed -i "s/REPLACE_CLUSTER_NAME/${env.CLUSTER_NAME}/g" k8s-addons/karpenter.yaml
                                sed -i "s|REPLACE_KARPENTER_ROLE_ARN|${env.KARPENTER_ROLE_ARN}|g" k8s-addons/karpenter.yaml
                            """
                        }

                        withCredentials([usernamePassword(credentialsId: 'github-cred', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                            sh """
                            git config user.email "jenkins@enterprise.com"
                            git config user.name "Jenkins GitOps"
                            git add charts/django-app/values.yaml

                            if [ "${params.DEPLOY_ENV}" = "prod" ]; then
                                git add k8s-addons/*.yaml
                            fi

                            git commit -m "ci(${params.DEPLOY_ENV}): Update image tag to ${IMAGE_TAG} [skip ci]"
                            git push https://${GIT_USERNAME}:${GIT_PASSWORD}@${GITHUB_REPO#https://} HEAD:main
                            """
                        }
                    }
                }
            }
        }
    }
}
