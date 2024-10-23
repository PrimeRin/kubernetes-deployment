# Deploying a Rails Application with MongoDB on Minikube

### Introduction
This guide covers the steps required to deploy a Ruby on Rails application with MongoDB as the database on Minikube. Minikube is a tool that helps run Kubernetes locally. In this deployment, we will set up a MongoDB service, configure Rails to use MongoDB (via Mongoid), and deploy both services (Rails and MongoDB) on Minikube.

### Prerequisites
Before starting, ensure you have the following installed and configured on your local machine:

- Minikube
- kubectl
- Docker
- Rails application with Mongoid setup (Rails 7.x and MongoDB)

---

### Deployment Steps

#### 1. Dockerize Rails App and Push to Docker Hub
The first step is to dockerize your Rails application and push the image to Docker Hub.

##### Step 1.1: Create a Dockerfile for the Rails App
In the root of your Rails application, create a Dockerfile:

```
# Use the official Ruby image
FROM ruby:3.3.0

# Set environment variables
ENV RAILS_ENV=development

# Set the working directory in the Docker container
WORKDIR /app

# Copy the Gemfile and Gemfile.lock to the container
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install

# Copy the entire Rails app into the container
COPY . .

# Expose the Rails server port
EXPOSE 3000

# Remove a potentially pre-existing server.pid for Rails
RUN rm -f tmp/pids/server.pid

# Command to run the Rails server
CMD ["rails", "server", "-b", "0.0.0.0"]
```

##### Step 1.2: Build the Docker Image
Use Docker to build the image for your Rails application. In the terminal, run the following command from your app's root directory:

```
docker build -t your-dockerhub-username/my-rails-app .
```

##### Step 1.3: Push the Docker Image to Docker Hub
Log in to your Docker Hub account from the terminal:

```
docker login
docker push your-dockerhub-username/my-rails-app
```
Now that your image is on Docker Hub, it can be pulled and deployed by Kubernetes in Minikube.

---

### 2. Start Minikube
Start Minikube to create a local Kubernetes cluster for the deployment:
```
minikube start
```

---

### 3. Create Secret for MongoDB Credentials
Create a Kubernetes secret to store MongoDB's root username and password, which will be used by both the MongoDB and Rails deployments.

Create a file mongo-secret.yaml:
```
apiVersion: v1
kind: Secret
metadata:
  name: mongo-secret
type: Opaque
data:
  mongo-root-username: cHJpbWU=  # base64 encoded 'prime'
  mongo-root-password: cGFzc3dvcmQ=  # base64 encoded 'password'
```

Apply the secret:

```
kubectl apply -f mongo-secret.yaml
```

---

### 4. Create ConfigMap for MongoDB Service
Create a ConfigMap to store the MongoDB service URL. Create a file mongo-configmap.yaml:

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: mongo-configmap
data:
  database_url: mongodb-service
```
Apply the ConfigMap:
```
kubectl apply -f mongo-configmap.yaml
```
---

### 5. MongoDB Deployment
Create the MongoDB deployment that will run MongoDB in a container and expose it as a Kubernetes service.

Create a file mongodb-deployment.yaml:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
        - name: mongodb
          image: mongo:4.4.6
          ports:
            - containerPort: 27017
          env:
            - name: MONGO_INITDB_ROOT_USERNAME
              valueFrom:
                secretKeyRef:
                  name: mongo-secret
                  key: mongo-root-username
            - name: MONGO_INITDB_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mongo-secret
                  key: mongo-root-password
---
apiVersion: v1
kind: Service
metadata:
  name: mongodb-service
spec:
  ports:
    - port: 27017
  selector:
    app: mongodb
  type: ClusterIP
```
---

### 6. Rails Deployment
Now, deploy your Rails application. The Rails app will be configured to communicate with MongoDB using environment variables.

Create a file rails-deployment.yaml:
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rails-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: rails-app
  template:
    metadata:
      labels:
        app: rails-app
    spec:
      containers:
        - name: rails-app
          image: your-dockerhub-username/my-rails-app:latest
          ports:
            - containerPort: 3000
          env:
            - name: ME_CONFIG_MONGODB_ADMINUSERNAME
              valueFrom:
                secretKeyRef:
                  name: mongo-secret
                  key: mongo-root-username
            - name: ME_CONFIG_MONGODB_ADMINPASSWORD
              valueFrom:
                secretKeyRef:
                  name: mongo-secret
                  key: mongo-root-password
            - name: ME_CONFIG_MONGODB_SERVER
              valueFrom:
                configMapKeyRef:
                  name: mongo-configmap
                  key: database_url
---
apiVersion: v1
kind: Service
metadata:
  name: rails-service
spec:
  selector:
    app: rails-app
  ports:
    - protocol: TCP
      port: 3000
      targetPort: 3000
      nodePort: 30000
  type: LoadBalancer
```
Apply the Rails deployment:

```
kubectl apply -f rails-deployment.yaml
```
---

### 7. Access Rails Application
Once the deployment is complete, access the Rails application using the Minikube IP:

```
minikube service rails-service
```
Minikube will provide the URL to access your application running on port 3000.

### Conclusion
You have now successfully dockerized a Ruby on Rails application, pushed the image to Docker Hub, and deployed both the Rails app and MongoDB on Minikube. Minikube allows you to test your application in a Kubernetes environment locally before deploying it to a production environment.
