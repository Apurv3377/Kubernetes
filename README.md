# Kubernetes

## Customized Scheduler

    Script : scheduler.py

    Algorithm :
        1. Monitor resources (memory) on worker nodes. (utility script resource.sh)
        2. Infinite watch on API server. 
        3. Fetch the objects with 'Pending State'
        4. Gather last 5 readings from resource monitor along with current consumption.
        5. Select best suitable worker node.
        6. Assign to the Object and Do the object binding.
    
    Libraries Used :
        paramiko for monitoring thread, kubernetes watch and config for object binding, resource.sh utility script should be present in home dir.
    
### Architecture
<img align="center" src="https://github.com/Apurv3377/Kubernetes/blob/master/scheduler.png">
    
   

## Reincarnation

### Reincarnation Types :
		
	1. Create New Pod before deleting the Old Pod (makes sure the downtime is 0 and application is running NRT)
	   script : migration.py
	   drawback : It is creating Pod with random new name every time. might cause application !
		
	2. Create Def Yaml with new destination worker node, and reincarnate followed with deletion of the old Pod. (It makes sure same Pod is reincarnated)
	   script : migration_dc.py
	   drawback : As deletion is performed before creation of the pod, there might be some downtime in the application.
### Use Cases :
#### Color Sensor Trigger
       
    Script : migration_color.py [Podname]
       
    Algorithm :
       1. From master/control node create a TCP socket on port 9081 and 9080 listening on requests
       2. Brick makes connection to control node using above TCP sockets
       3. When connection is established, send the IP Address of a current Data Node/ Worker Node.
       4. Application is Running Now
       5. Control node waits infinitely on the color sensor trigger.
       6. When trigger is sent to control node, script triggers the transfer of the data plane from one worker node to new.
       7. Before deletetion of the old communication path, new communication path is ensured. (Type 1)
       
    Libraries Used :
       kubernetes python API, ruamel for yaml manipulation, multithreading for infinite watch.
       
    Official Documentation Links :
       https://github.com/kubernetes-client/python
       https://yaml.readthedocs.io/en/latest/

    Pod Definition :
    float_pod1.yaml
    
    hostNetwork: true
    dnsPolicy: ClusterFirstWithHostNet


#### Architecture
<img align="center" src="https://github.com/Apurv3377/Kubernetes/blob/master/ColorBasedR.png">

#### Manual Trigger with Abstraction of Data Plane
    
    Script : migration.py
    
    Algorithm :
        1. Reincarnation is triggered as soon as script is executed.
        2. New Pod with new random name is created
        3. Serves until container inside newly created pod is running.
        4. When new container is ready and old is deleted, requests are automatically directed towards new container.
#### Architecture
    In this setup MetalLB is external Load Balancer which is making services available outside the cluster. and NGINX Ingress is allowing traffic inside the cluster.
    MetalLB setup is in utilities section.
<img align="center" src="https://github.com/Apurv3377/Kubernetes/blob/master/dataplaneabs.png">

## Useful Links
    Assorted Bookmarks in bookmarks1.html


## Utilities
### Resource Monitoring
    
        Retrieve CPU and Memory usage on the Node. In terms of Requested and Limits. Uses Kubectl internally.
        
        sh resource.sh [node] [cpu/mem] [req/lim] [per]
        
### MetalLB Setup
<img width="200" height="200" src="https://github.com/Apurv3377/Kubernetes/blob/master/logo.png ">

- **Installation with Kubernetes manifests**

```
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.7.3/manifests/metallb.yaml
```
This will deploy MetalLB to your cluster, under the metallb-system namespace. The components in the manifest are:
The metallb-system/controller deployment. This is the cluster-wide controller that handles IP address assignments.
The metallb-system/speaker daemonset. This is the component that speaks the protocol(s) of your choice to make the services reachable.
Service accounts for the controller and speaker, along with the RBAC permissions that the components need to function.

- **Layer 2 configuration**

The following configuration gives MetalLB control over IPs from 172.18.0.50 to 172.18.0.60, and configures Layer 2 mode

    apiVersion: v1
    kind: ConfigMap
    metadata:
      namespace: metallb-system
      name: config
    data:
      config: |
        address-pools:
        - name: default
          protocol: layer2
          addresses:
          - 172.18.0.50-172.18.0.60
    
    
### Harbor Setup

<img width="520" height="200" src="https://github.com/Apurv3377/Kubernetes/blob/master/harbor_logo.png ">

#### Step 1. Install Docker and docker-compose on a Harbor Ubuntu Server

1. SSH to your new Ubuntu 16.04 server.
    ```
    $ ssh user@172,18,0,179
    ```
2. Add the Docker GPG key.
    ```
    $ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    
    sudo apt-key add -
    ```
3. Add the Docker repository.
    ```
    sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
    ```
4. Install Docker.
    ```
    sudo apt-get update
    sudo apt-get install docker-ce
    ```
5. Allow non sudo user to use Docker without administrator privileges.
    ```
    sudo usermod -aG docker $USER
    ```
6. Exit the SSH session.
    ```
    $ exit
    ```
7. Log back in and check the Docker commands working with non sudo priviledge
    ```
    docker info
    ```
8. Install Docker Compose
    ```
    $ sudo apt-get install docker-compose
    ```
#### Step 2. Generate self-signed certificates

1. Create a certificate authority.
    ```
    $ openssl req \
    -newkey rsa:4096 -nodes -sha256 -keyout ca.key \
    -x509 -days 3650 -out ca.crt
    ```
2. Generate a certificate signing request.
    ```
    $ openssl req \
    -newkey rsa:4096 -nodes -sha256 -keyout harbor.aexlab.io.key \
    -out harbor.aexlab.io.csr
    ```
3. Create a configuration file for the Subject Alternative Name.
    ```
    $ vim extfile.cnf
    subjectAltName = IP:172.18.0.179
    ```
4. Generate a certificate.
    ```
    $ openssl x509 -req -days 3650 \
    -in harbor.aexlab.io.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -extfile extfile.cnf \
    -out harbor.aexlab.io.crt
    ```
5. Copy the certificate to /etc/ssl/certs.
    ```
    $ sudo cp *.crt *.key /etc/ssl/certs
    ```
    
#### Step 3. Install Harbor

1. Download the Harbor online installer.
    ```
    $ wget https://storage.googleapis.com/harbor-releases/harbor-online-installer-v1.5.2.tgz
    ```
2. Untar the installer.
    ```
    $ tar xvzf harbor-online-installer-v1.5.2.tgz
    ```
3. Go to the Harbor directory.
    ```
    $ cd harbor
    ```
4. Edit the Harbor configuration and change the following options in the file.
    ```
    $ vim harbor.cfg
    hostname = 172.18.0.179
    ui_url_protocol = https
    ssl_cert = /etc/ssl/certs/harbor.aexlab.io.crt
    ssl_cert_key = /etc/ssl/certs/harbor.aexlab.io.key
    harbor_admin_password = [your_harbor_admin_password]
    db_password = [your_db_password]
    clair_db_password = [your_clair_db_password]
    ```
5. Install Harbor.
    ```
    $ sudo ./install.sh --with-notary --with-clair
    ```     
#### Step 4. Configuring the Docker daemon of the Kubernetes worker nodes

The following steps have to be repeated for each of your Kubernetes worker nodes.

1. Copy the certificate authority from the Harbor machine to your Kubernetes worker node.
    ```
    $ scp ../ca.crt user@172.18.0.179:~
    ```
2. SSH to your Kubernetes worker nodes.
    ```
    $ ssh user@172.18.0.179
    ```
3. Create a directory for the certificate authority.
    ```
    $ sudo mkdir -p /etc/docker/certs.d/172.18.0.179
    ```
4. Move the certificate authority to the new directory.
    ```
    $ sudo mv ca.crt /etc/docker/certs.d/172.18.0.179
    ```
5. Restart the Docker daemon.
    ```
    $ sudo systemctl restart docker
    ```

#### Step 5. Configuring Kubernetes

1. From your client machine, create a Kubernetes secret object for Harbor.

    ```
    $ kubectl create secret docker-registry harbor \
    --docker-server=https://172.18.0.179 \
    --docker-username=admin \
    --docker-email=aexlab@aexlab.io \
    --docker-password='[your_admin_harbor_password]'
    ```

#### Step 6. Deploying a private container image

- **Configure the client machine Docker daemon**

1. Download the certificate authority from the Harbor machine.
    ```
    $ scp user@172.18.0.179:~/ca.crt .
    ```
2. Create a directory for the certificate authority.
    ```
    $ sudo mkdir /etc/docker/certs.d/172.18.0.179
    ```
3. Move the certificate authority to the new directory.
    ```
    $ sudo mv ca.crt /etc/docker/certs.d/172.18.0.179
    ```
4. Restart the Docker daemon.
    ```
    $ sudo systemctl restart docker
    ```

- **Create a private image**

1. Access the Harbor web interface, browse to https://172.18.0.179 and login with the admin user.
2. Create a new project.
3. Call it private and leave the public checkbox unchecked.
4. Download the public image from Kubernetes Up & Running book.
    ```
    $ docker pull localization_handling
    ```
5. Tag the image to use your Harbor private registry.
    ```
    $ docker tag localization_handling 172.18.0.179/videoapp/localization_handling
    ```
6. Login to the Harbor private registry.
    ```
    $ docker login 172.18.0.179
    ```
7. Upload the image to the private Harbor registry.
    ```
    $ docker push 172.18.0.179/videoapp/localization_handling
    ```
8. Check that the image has been properly uploaded to the Harbor private registry.

- **Deploy the private image on the Kubernetes cluster**

1. Create a manifest for the deployment.
    
    ```
    apiVersion: v1
    kind: Pod
    metadata:
      name: foobar-stress5
      namespace: default
      labels:
        app: videoapp
    spec:
      schedulerName: foobar
      containers:
      - image: 172.18.0.179/videoapp/tcp_server_image_viewer
        name: videoapp1
        ports:
        - containerPort: 11111
        - containerPort: 7771
      - image: 172.18.0.179/videoapp/localization_handling
        name: videoapp2
        ports:
        - containerPort: 11112
      imagePullSecrets:
      - name: harbor
    
    ```

2. Launch the deployment.
    ```
    $ kubectl apply -f deployment.yaml
    ```
3. Check that Kubernetes was able to download the private kuard image.
    ```
    $ kubectl get pods
    ```


### NGINX Ingress Setup

<img width="220" height="200" src="https://github.com/Apurv3377/Kubernetes/blob/master/nginx.png ">

#### Prerequisites

Make sure you have access to the Ingress controller image:

    clone https://github.com/nginxinc/kubernetes-ingress.git
    

#### 1. Create a Namespace, a SA, the Default Secret, the Customization Config Map, and Custom Resource Definitions

1. Create a namespace and a service account for the Ingress controller:
    ```
    kubectl apply -f common/ns-and-sa.yaml
    ```

1. Create a secret with a TLS certificate and a key for the default server in NGINX:
    ```
    $ kubectl apply -f common/default-server-secret.yaml
    ```

1. Create a config map for customizing NGINX configuration 
    ```
    $ kubectl apply -f common/nginx-config.yaml
    ```



#### 2. Configure RBAC

If RBAC is enabled in your cluster, create a cluster role and bind it to the service account, created in Step 1:

   
    $ kubectl apply -f rbac/rbac.yaml
    


#### 3. Deploy the Ingress Controller

We include two options for deploying the Ingress controller:
* *Deployment*. Use a Deployment if you plan to dynamically change the number of Ingress controller replicas.
* *DaemonSet*. Use a DaemonSet for deploying the Ingress controller on every node or a subset of nodes.

##### 3.1 Create a Deployment

For NGINX, run:

    
    $ kubectl apply -f deployment/nginx-ingress.yaml
    


##### 3.2 Create a DaemonSet

For NGINX, run:


    $ kubectl apply -f daemon-set/nginx-ingress.yaml



##### 3.3 Check that the Ingress Controller is Running

Run the following command to make sure that the Ingress controller pods are running:

    $ kubectl get pods --namespace=nginx-ingress
  
    
    
### Prometheus and Grafana Setup

<img width="320" height="200" src="https://github.com/Apurv3377/Kubernetes/blob/master/grafana-prometheus.png ">

#### Quick start

To quickly start all the things just do this:

    kubectl apply \
      --filename https://raw.githubusercontent.com/giantswarm/kubernetes-prometheus/master/manifests-all.yaml
    

This will create the namespace `monitoring` and bring up all components in there.

To shut down all components again you can just delete that namespace:

    kubectl delete namespace monitoring
    

#### Default Dashboards

If you want to re-import the default dashboards from this setup run this job:

    kubectl apply --filename ./manifests/grafana/import-dashboards/job.yaml
    

In case the job already exists from an earlier run, delete it before

    kubectl --namespace monitoring delete job grafana-import-dashboards
    

To access grafana you can use port forward functionality

    kubectl port-forward --namespace monitoring service/grafana 3000:3000
    
And you should be able to access grafana on `http://localhost:3000/login` with admin/admin
