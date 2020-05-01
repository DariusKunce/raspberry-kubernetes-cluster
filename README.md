# Raspberry Pi Kubernetes cluster



## Setting up Pis

1. Download [Ubuntu Server for Raspberry Pi](https://ubuntu.com/download/raspberry-pi). I used Ubuntu Server as I have Raspberry Pi 4s with 4GB of ram each, and at the moment Rasbian has no official 64 bit build. 

1. Flash the SD cards with downloaded Ubuntu image using [balena Etcher](https://www.balena.io/etcher/).

1. When Etcher has done it's work and before booting Raspberry Pi, we have to enable SSH access, as we will be building a headless setup. Reinsert the SD card so that the OS would mount it and create an empty text file named **ssh** in the card's boot directory:   
Mac OS:  `$ touch /Volumes/system-boot/ssh`  
Ubuntu: `$ touch /media/{user}/system-boot/ssh`

1. Start Pis and ssh into them: `ssh ubuntu@192.168.1.253`. Use `ubuntu` as password. In order to determine the IP addresses, use the `arp` utility as described [here.](https://ubuntu.com/tutorials/how-to-install-ubuntu-on-your-raspberry-pi#4-boot-ubuntu-server)

## Setting up Kubernetes

1. TODO:  Prepare Pis for Kubernetes (cgroups).

1. Install k3s (a lightweight version of k8s) on master and agent Pis:  
master node: `$ curl -sfL https://get.k3s.io | sh -`  
agent nodes: `$ curl -sfL https://get.k3s.io | K3S_URL=https://{Master Node IP}:6443 K3S_TOKEN=MasterNodeToken sh -`  
Master node token can be found here: `/var/lib/rancher/k3s/server/node-token`

1. Install kubectl on your machine in order to manage cluster remotely. On Ubuntu:    
    ```shell
    sudo apt-get update && sudo apt-get install -y apt-transport-https gnupg2
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubectl
    ```

1. Copy Kubernetes config from master node `/etc/rancher/k3s/k3s.yaml` to your machine `/home/{user}/.kube/config`

1. Start a private Docker repository:  
    `docker run -d -p 5000:5000 --restart=always --name registry registry:2`

1. Configure k3s to whitelist insecure private Docker repository.  
    Add this:
    ```yaml
    mirrors:
      "192.168.1.251:5000": # <- Private Docker repo IP
        endpoint:
          - "http://192.168.1.251:5000" # <- Private Docker repo IP
    ```
    to these: 
    on master node - `/etc/rancher/k3s/registries.yaml`, then run `sudo service k3s restart`
    on agent nodes - `/etc/rancher/k3s-agent/registries.yaml`, then run `sudo service k3s-agent restart`

1. TODO: Install Kubernetes dashboard.

1. TODO: Access Kubernetes dashboard.

## Run a test ASP.NET Core app

1. Create a new ASP.NET Web API project:   
`$ dotnet new webapi`

1. Edit `/etc/docker/daemon.json` to whitelist our private Docker registry.  Add this:
    ```json
    {
    "insecure-registries" : ["192.168.1.251:5000"]
    }
    ```

1. Use `deploy.sh` to build, publish and run the app on a Kubernetes cluster.