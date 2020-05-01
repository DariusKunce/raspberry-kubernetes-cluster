# Raspberry Pi Kubernetes cluster



## Setting up Pis

1. Download [Ubuntu Server for Raspberry Pi](https://ubuntu.com/download/raspberry-pi). I used Ubuntu Server as I have Raspberry Pi 4s with 4GB of ram each, and at the moment Rasbian has no official 64 bit build. 

1. Flash the SD cards with downloaded Ubuntu image using [balena Etcher](https://www.balena.io/etcher/).

1. When Etcher has done it's work and before booting Raspberry Pi, we have to enable SSH access, as we will be building a headless setup. Reinsert the SD card so that the OS would mount it and create an empty text file named **ssh** in the card's boot directory:   
    Mac OS:  `$ touch /Volumes/system-boot/ssh`  
    Ubuntu: `$ touch /media/{user}/system-boot/ssh`  
    
    As we are already here, append this: `cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1` at the end of the line here: `/Volumes/system-boot/ssh/nobtcmd.txt`. This is needed for Kubernetes to run on our Ubuntu instances. And, `nobtcmd.txt` translates to 'no bluetooth', which is enabled by default. If bluetooth is enabled, then `btcmd.txt` needs to be changed instead.


1. Start Pis and ssh into them: `ssh ubuntu@192.168.1.253`. Use `ubuntu` as password. In order to determine the IP addresses, use the `arp` utility as described [here.](https://ubuntu.com/tutorials/how-to-install-ubuntu-on-your-raspberry-pi#4-boot-ubuntu-server)

## Setting up Kubernetes

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

1. Install Arkade, which will simplify running of a Kubernetes dashboard: `curl -sSL https://dl.get-arkade.dev | sudo sh`.    
Then: `arkade install kubernetes-dashboard`, and we have a running dashboard.

1. In order to access the dashboard, first create an admin user as described [here.](https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md)

1. Then, note the access token: `sudo kubectl -n kubernetes-dashboard describe secret $(sudo kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')`

1. Run `kubectl proxy`

1. Now the dashboard is only accessible from within a Kubernetes node. In order to access it from you pc, use ssh tunnel: `ssh -L localhost:8001:localhost:8001 ubuntu@192.168.1.253 -N`

1. Access dashboard from your machine here: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login

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