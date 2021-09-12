# k8s-node-collector

K8s-node-collector is an open source application that periodically analyzes the open ports of the our cluster nodes in kubernetes and saves them in a report directory in the most convenient path.

## Table of content

<!-- TABLE OF CONTENTS -->
  * [Getting Started](#getting-started)
    * [About the Project](#about-the-project)
    * [Prerequisites](#prerequisites)
  * [Create ServiceAccount | RBAC](#create-serviceaccount)
  * [Persistent Storage](#persistent-storage)
  * [Docker container](#docker-container)
  * [Script collector.sh](#script-collector.sh)
  * [Run and configure k8s-node-collector](#run-and-configure-k8s-node-collector)
      * [Values](#values)
  * [License](#license)


## Getting Started ⭐️ <a name="getting-started"/>

### About the project 💡 <a name="about-the-project"/>

In order to use k8s-node-report this project uses the <b>k8s-node-collector</b> docker image as a container resource that will run periodically through a kubernetes CronJob manifest. When the Cronjob starts it will deploy the necessary jobs with their corresponding pods that will extract the information from the nodes. Following this guide will advance on the previous steps necessary to implement the solution.

### Prerequisites 🧾 <a name="prerequisites"/>
* This project assumes that you already have a cluster of kubernetes running with one and multiple worker nodes. It can be in any public / private cloud or on-premises.
* We also assume that we have generated a storage class in our cluster that will later be used to generate volumes to store the reports.


## Create ServiceAccount | RBAC 🔧  <a name="create-serviceaccount"/>

If we want to fetch information from the workes nodes we need our pods to be able to authenticate and make calls to the k8s API. To achive this we will:
1. Create a k8s role with required permissions
2. Create a k8s service account
3. Create a role-binding with role and serviceaccount created above

  ```sh
  kubectl apply -f sa-rolebinding.yaml
  ```
The pods our CronJob generates will use this service account to access k8s api.

❗️ It is recommended for a production environment to generate a service account with only the permissions our resorces will use [create, list, update, watch ....] in this example we will use admin permissions.

## Persistent Storage 💾  <a name="persistent-storage"/>

The idea is that the port reports that k8s-node-collector generates are persistent over time and can be accessible to other resources if they are necessary. To do this we are going to create a PVC-type resource in k8s, which will later be used by our persist volume (PV). As mentioned in the prerequisites, it is assumed that a Storage Class already exists in our cluster. This example is used with one called gp2 but may need to be modified in each case.

  ```sh
  kubectl apply -f claim.yaml
  ```
  
  ## Docker container 🐳  <a name="docker-container"/>
  
The k8s-node-collector solution has a docker image that contains several tools already packaged that the CronJob will use, such as as wget to download the collector.sh (script that extracts the ports of the nodes) or kubectl (necessary for make calls to the k8s api)
  
  https://hub.docker.com/r/alvarolg/k8s-node-collector

  ## Script collector.sh 🔬 <a name="script-collector.sh"/>

The [collector.sh](scripts/collector.sh) script has two main parts:

* When the k8s-node-collector Job is called by the cronjob, a main pod will run, which will download the most up-to-date version of the collector.sh script. It will create a list of all available nodes in our cluster and generate a secondary pod manifest for each node.

* Subsequently, it launches a secondary pod in each of the nodes of our cluster. This secondary pod will run a netstat command in the same network namespaces of the host, it will save the information in our report file inside the persistent storage and delete when completed. This action will be done one by one for each of the nodes of our cluster until we have information on all of them.

 ❗️ So the secondary pod can access the nodes network namespace it includes declared the HostNetwork as <b>true</b> this can be a security risk, so bear in mind this before running this in a productive enviroment. More information regarding Security Policies and HostNamespaces:  https://kubernetes.io/docs/concepts/policy/pod-security-policy/#host-namespaces
 
 ![Alt Text](https://j.gifs.com/oZyykj.gif)
  
  ## Run and configure k8s-node-collector <a name="run-and-configure-k8s-node-collector"/>
  
 As mentioned, to execute k8s-node-collector it is preferable to use a Cronjob manifest that allows schedule the moment when the reports will be generated, in any way, any other type such as jobs, deployments or pods could be configured equally. (For this example it'll generate the report every night at 3:00 AM)
 
   ```sh
  kubectl apply -f cronjob.yaml
  ```
 
  ### Values <a name="values"/>
  
  * The pod will use the SA created in the previous point
  * The environment variable PATH_REPORTS will be where the generated report will be saved. It is customizable in each case. If there is no value it will simply be omitted
  * No history of Jobs is needed so it is added success/failed JobsHistoryLimit
  * The pod will reboot in case of failure.
  
## License <a name="license"/>

Distributed under the GNU General Public License v3.0 License. See `LICENSE` for more information.
