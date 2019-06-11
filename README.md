# Kubernetes

Resource.sh 

Retrieve CPU and Memory usage on the Node. In terms of Requested and Limits. Uses Kubectl internally..

echo  'Usage : '

echo  'sh resource.sh [node] [cpu/mem] [req/lim] [per]'

echo 'req : Requests, lim : Limits, per : Percentage'


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
<img align="center" src="kubernetes/scheduler.png">
    
   

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
<img align="center" src="kubernetes/ColorBasedR.png">

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
<img align="center" src="kubernetes/dataplaneabs.png">

## Useful Links
    Assorted Bookmarks in bookmarks1.html


## Utilities
### Resource Monitoring
    
        Retrieve CPU and Memory usage on the Node. In terms of Requested and Limits. Uses Kubectl internally.
        
        sh resource.sh [node] [cpu/mem] [req/lim] [per]
        
### MetalLB
    
### Harbor
        
      





