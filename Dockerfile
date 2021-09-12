#Debian base image
FROM debian:stable

#Create working directory
WORKDIR /app

#Installing dependecies
RUN apt-get update -y && apt-get install wget curl -y

#Installg kubectl
RUN wget https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl

#Download and execute last version of collector.sh
CMD ["bash", "-c", "wget https://raw.githubusercontent.com/Var091/k8s-node-collector/main/scripts/collector.sh -P /app/ ; chmod +x /app/collector.sh ; sh /app/collector.sh ${PATH_REPORT}"]
