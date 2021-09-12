# k8s-node-collector

K8s-node-collector is an open source application that periodically analyzes the open ports of the our cluster nodes in kubernetes and saves them in a report directory in the most convenient path.

## Table of content

<!-- TABLE OF CONTENTS -->
  * 1 [Getting Started](#getting-started)
    * [About the Project](#about-the-project)
    * [Prerequisites](#prerequisites)
  * 2 [Create ServiceAccount | RBAC](#create-serviceaccount)
  * 3 [Persistent Storage](#persistent-storage)
  * 4 [Docker container](#docker-container)
  * 5 [Script collector.sh](#script-collector.sh)
  * 6 [Run and configure k8s-node-collector](#run-and-configure-k8s-node-collector)
      * [Values](#values)
  * 7 [License](#license)


## Getting Started ⭐️ <a name="getting-started"/>

### About the project 💡 <a name="about-the-project"/>

In order to use k8s-node-report this project uses the <b>k8s-node-collector</b> docker image as a container resource that will run periodically through a kubernetes CronJob manifest. When the Cronjob starts it will deploy the necessary jobs with their corresponding pods that will collect the information from the nodes. Follow this documentation for implementation.

### Prerequisites 🧾 <a name="prerequisites"/>
* This project assumes that you already have a cluster of kubernetes running with one and multiple worker nodes. It can be in any public / private cloud or on-premises.
* It also assumes that there's a storage class configured in the cluster that will later be used to generate volumes to store the reports.


## Create ServiceAccount | RBAC 🔧  <a name="create-serviceaccount"/>

If we want to fetch information from the workes nodes we need our pods to be able to authenticate and make calls to the k8s API. To achive this we will:
1. Create a k8s role with required permissions
2. Create a k8s service account
3. Create a role-binding with role and serviceaccount created above

  ```sh
  kubectl apply -f sa-rolebinding.yaml
  ```
The pods our CronJob generates will use this service account to access k8s api.

❗️ It is recommended for a production environment to generate a service account with only the permissions our resorces will use [create, list, update, watch ....] in this example we will use admin permissions. More about Roles and ClusterRoles: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole

## Persistent Storage 💾  <a name="persistent-storage"/>

The reports should be persistent over time and accessible to other resources if necessary. To do this we are going to create a PVC-type resource in k8s, which will later be used by our persist volume (PV). As mentioned in the prerequisites, it is assumed that a Storage Class already exists in our cluster. This example is used with one called gp2 but may need to be modified in each case.

  ```sh
  kubectl apply -f claim.yaml
  ```
  
  ## Docker container 🐳  <a name="docker-container"/>
  
The k8s-node-collector solution has a docker image that contains several tools already packaged that the CronJob will use, such as as wget to download the collector.sh (script that collects open ports of nodes) or kubectl (necessary for make calls to the k8s api)
  
  https://hub.docker.com/r/alvarolg/k8s-node-collector

  ## Script collector.sh 🔬 <a name="script-collector.sh"/>

The [collector.sh](scripts/collector.sh) script has two main parts:

* When the k8s-node-collector Job is called by the CronJob, a main pod will run, which will automatically download the most up-to-date version of the collector.sh . It will use a list of all available nodes in our cluster and generate a secondary pod manifest for each node.

* Subsequently, it launches a secondary pod in each of the nodes of our cluster. This secondary pod will run <b>netstat</b> command in the <b>same network namespaces of the host</b>. It will save the information in our report file inside the PV and delete itself when completed. This action will be done one by one for each of the nodes of our cluster until we have information of all of them.

![Alt Text](https://j.gifs.com/oZyykj.gif)

 ❗️ So the secondary pod can use the nodes network namespace it includes declared the HostNetwork as <b>true</b> this can be a security risk, so bear in mind this before running this in a productive enviroment. More information regarding Security Policies and HostNamespaces:  https://kubernetes.io/docs/concepts/policy/pod-security-policy/#host-namespaces
 
  
  ## Run and configure k8s-node-collector <a name="run-and-configure-k8s-node-collector"/>
  
As mentioned, when running k8s-node-collector it is preferable to use a Cronjob manifest that allows scheduling for the moment when the reports will be generated. However, any other resource type such as jobs, deployments or pods could be configured equally. (For this example it'll generate the report every night at 3:00 AM)
 
   ```sh
  kubectl apply -f cronjob.yaml
  ```
 
  ### Values <a name="values"/>
  
  * The pod will use the SA created in the point 2
  * The environment variable PATH_REPORTS will be where the generated report will be saved. It is customizable in each case. If there is no value it will simply be omitted
  * No history of Jobs is needed so the <b>success/failed JobsHistoryLimit</b> is added .
  * The pod will reboot in case of failure.
  
## License <a name="license"/>

Distributed under the GNU General Public License v3.0 License. See `LICENSE` for more information.
