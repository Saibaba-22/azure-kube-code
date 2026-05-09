# AZURE--KUBERNETES--CODE

# Kubernetes README

## What is Kubernetes?

Kubernetes (K8s) is an open-source container orchestration platform used to:

* Deploy applications
* Scale applications
* Manage containers automatically
* Handle networking and load balancing
* Perform self-healing

---

# Kubernetes Architecture

```text
Master Node
│
├── API Server
├── Scheduler
├── Controller Manager
└── ETCD

Worker Node
│
├── Kubelet
├── Kube Proxy
└── Pods
```

---

# Kubernetes Components

| Component  | Purpose                  |
| ---------- | ------------------------ |
| Pod        | Smallest deployable unit |
| Deployment | Manages pod replicas     |
| Service    | Exposes application      |
| Namespace  | Logical isolation        |
| ConfigMap  | Store configuration      |
| Secret     | Store sensitive data     |
| Ingress    | HTTP/HTTPS routing       |
| Node       | Worker machine           |

---

# Basic Kubernetes Commands

## Cluster Commands

```bash
kubectl cluster-info
kubectl get nodes
kubectl get namespaces
```

---

## Pod Commands

```bash
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl delete pod <pod-name>
```

---

## Deployment Commands

```bash
kubectl get deployments
kubectl apply -f deployment.yaml
kubectl delete -f deployment.yaml
kubectl scale deployment nginx-deployment --replicas=3
```

---

## Service Commands

```bash
kubectl get svc
kubectl describe svc nginx-service
```

---

# Kubernetes Deployment YAML

## deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

---

# Kubernetes Service YAML

## service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
```

---

# Deploy Application

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

---

# Verify Application

```bash
kubectl get pods
kubectl get svc
```

---

# Kubernetes Scaling

```bash
kubectl scale deployment nginx-deployment --replicas=5
```

---

# Kubernetes Rolling Update

```bash
kubectl set image deployment/nginx-deployment nginx=nginx:latest
```

---

# Kubernetes Rollback

```bash
kubectl rollout undo deployment nginx-deployment
```

---

# Kubernetes Namespaces

```bash
kubectl create namespace dev
kubectl get namespaces
```

---

# Kubernetes ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config

data:
  ENV: production
```

---

# Kubernetes Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret

type: Opaque

data:
  username: YWRtaW4=
  password: MTIzNA==
```

---

# Troubleshooting Commands

```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl get events
kubectl top nodes
```

---

# Kubernetes Features

* Auto Scaling
* Self Healing
* Load Balancing
* Service Discovery
* Rolling Updates
* Secret Management
* Storage Orchestration

---

# Best Practices

* Use namespaces
* Use resource limits
* Store secrets securely
* Use health checks
* Enable monitoring
* Use rolling updates
* Maintain backup strategy

---

# Author

Saibaba Kola
