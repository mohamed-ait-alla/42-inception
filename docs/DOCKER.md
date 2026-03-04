# Docker

---

## Overview
`Docker` is a software that runs on linux and windows. It creates, manages, and can even orchestrate containers.

The name "Docker" is referring to either of the following:
- Docker, Inc The company.
- Docker The technology.

## The Docker Technology
There are three most important things must be aware when we talking about `Docker` as a technology:
- **The runtime**
- **The daemon**
- **The orchestrator**

<br>
<img src="./assets/docker-architecture.png" alt="Docker Architecture">
</br>

The `runtime` operates at the lowest level and is responsible for starting and stopping containers (this includes building all of the OS constructs such as namespaces and cgroups). Docker implements a tiered runtime
architecture with high-level and low-level runtimes that work together.

The low-level runtime is called `runc`. It's job is to interface with the underlying OS and start and stop containers. Every running container on a Docker node has a runc instance managing it.

The high-level runtime is called `containerd`. It's job is to manage the lifecycle of a container, including pulling images, creating network interfaces, and managing lower-level `runc` instances. A typical Docker instalation has a single containerd process (docker-containerd) controlling the runc (docker-runc) instances associated with each running container.

The Docker `daemon` (dockerd) sits above containerd and performs higher-level task such exposing the docker remote API, managing images, managing volumes, managing networks and more...


The Docker `swarms` is a native technology that is used to manage clusters or nodes running docker, it's like Kubernetes. just kubernetes it's common used.

## The Docker Engine
In this part we'll take a quick look under the hood of the Docker Engine. and we'll split it into three main sections:
- The TLDR
- The deep dive
- The commands

### The Docker Engine - The TLDR

The `Docker Engine` is the core software that runs and manages containers. and is build from many small specialised tools.

In short, Docker engine is like a car engine, both are modular and created by connecting many small specialized parts:

- A car engine is made from many specialized parts that work together to make a car drive, intake, manifolds etc.
- The `Docker Engine` is made from many specialized tools that work together to create and run containers, APIs, execution driver etc.

The major components that make up the Docker engine are `the Docker daemon`, `containerd`, `runc`, and various plugins such as networking and storage.

<br>
<img src="./assets/docker-engine-components.png" alt="Docker Engine Architecture">
</br>

These components together are create and run containers.

### The Docker Engine - The Deep Dive

When Docker was first released, the Docker engine had two major components:
- The Docker daemon
- LXC

The **Docker daemon** is a binary that contains all of the code for the Docker client, the Docker API, the container runtime, image builds and much more.

**LXC** provided the daemon with access to the fundamentals building-blocks of containers that existed in the linux kernel. Things like *namespaces* and *control groups (cgroups)*.

<br>
<img src="./assets/original-docker-arch.png" alt="Docker Engine Architecture">
</br>

The figure shows the old Docker Engine architecture.

Next, Docker Inc, updated it and developped `libcontainer` tool that replaced `LXC`, also it refactored the `docker daemon` into small and specialized tools.

<br>
<img src="./assets/current-docker-arch.png" alt="Docker Engine Architecture">
</br>

This picture shows a high-level view of the current Docker engine architecture.
let's explain some of these refactored things:
- **`runc:`** is the reference implementation of the OCI (Open Container Initiative) container-runtime-spec. it's a small, lightweight CLI wrapper for `libcontainer`. It's job is to create containers.

- **`containerd:`** is a tool that manages the container lifecycle operations (start | stop | pause | rm...). It has also some other functionalities like image pulls, volumes and networks.


So, Now that we have a view of the big picture, let's walk through the process of creating a new container:
1. launching the container using the command `docker container run --name ctr1 -it alpine:latest sh`
2. The Docker client converts the command into the appropriate API payload and POSTs it to the API endpoint exposed by the Docker daemon.
3. Once the daemon receives the command to create a new container, it makes a call to containerd.
4. containerd converts the required Docker image into an OCI bundle and tells runc to create a new container.
5. runc interfaces with the OS kernel to pull together al of the constructs necessary to create a container (namespaces, cgroups etc).
6. The container process is started as a child process of runc and as soon as it is started runc will exit.
7. The container is now started.

The process is summarized in picture bellow.

<br>
<img src="./assets/container-starting-lifecycle.png" alt="Docker Engine Architecture">
</br>

Some of the diagrams above have shown a shim component, so what is it?

**what is shim**
We mentioned earlier that containerd uses runc to create new containers. In fact, it forks a new instance of runc
for every container it creates. However, once each container is created, the parent runc process exits.

Once a container's parent runc exits, the associated `containerd-shim` process becomes the container's parent.

## Docker Images
In this part we're going to get a solid understanding of what Docker images are, how to perform basic operations, and how they work
under-the-hood.

As usual, we'll split this part into three main sections:
- The TLDR
- The deep dive
- The commands


### Docker Images - The TLDR
A Docker image is a unit of packaging that contains everything required for an application to run. This includes code, dependencies, and OS constructs.

You can think if Docker images as similar to VM templates. A VM template is like a stopped VM, A Docker image is like a stopped container.

You get Docker images by pulling them from an image registry (most common is Docker Hub). The pull operation downloads the image to your local Docker host where Docker can use it to start one or more containers.

### Docker Images - The deep dive
We've mentioned earlier that `images` are like stopped containers. In fact, you can stop a container and create a new image from it. With this in mind, `images` are considered build-time constructs, whereas `containers` are run-time constructs.

<br>
<img src="./assets/images-vs-containers.png" alt="Images and Containers">
</br>

The picture shows a high-level view of the relationship between images and containers.
Once you've started a container from an image, the two constructs become dependant on each other and you cannot delete the image untill the last container using it stopped and destroyed. Attempting to delete an image without stopping and destroying all containers using it will result in an error.

The process of getting images onto a Docker host is called *pulling*. So to pull the latest image on a Docker host, we've to pull it using the command `docker image pull redis:latest`, Then enter `docker image ls` to check your pulled images.

The following examples shows how to pull various different images from *offcial repositories*:

```bash
$ docker image pull mongo:4.2.6
// This will pull the image tagged as `4.2.6` from the official `mongo` repository.

$ docker image pull busybox:latest
// This will pull the image tagged as `latest` from the official `busybox` repository.

$ docker image pull alpine
// This will pull the image tagged as `latest` from the official `alpine` repository.
```

A couple of points about those commands.

First, if you **do not** specify an image tag after the repository name, Docker will assume you're referring to the image tagged as latest. In case of the repository doesn't have an image tagged as latest the command will fail.

Second, the latest tag does not guarantee it is the most recent image in a repository. For example, the most recent image in the alpine repository is usually tagged as edge.


A Docker image is just a bunch of loosely-connected read-only layers, with each layer comprising one or more files. This is shown in picture bellow.

<br>
<img src="./assets/image-overview.png" alt="Image Overview">
</br>

Docker takes care of stacking these layers and representing them as a single unified object.

There are a few ways to see and inspect the layers that make up an image, considering this example:
```bash
$ docker image pull ubuntu:latest
latest: Pulling from library/ubuntu
952132ac251a: Pull complete
82659f8f1b76: Pull complete
c19118ca682d: Pull complete
8296858250fe: Pull complete
24e0251a0e2c: Pull complete
Digest: sha256:f4691c96e6bbaa99d...28ae95a60369c506dd6e6f6ab
Status: Downloaded newer image for ubuntu:latest
docker.io/ubuntu:latest
```
Each line in the example above that ends with "Pull complete" represents a layer in the image that was pulled. So in that example the image has 5 layers.

Another way to see the layers of an image is to inspect the image with the command `docker image inspect`.

Earlier, we've shown how to pull images using their name(tag). This is by far the most common method, but it has a problem, tags are mutable! this means it’s possible to accidentally tag an image with the wrong tag(name). Sometimes, it’s even possible to tag an image with the same tag as an existing, but diﬀerent, image. this
can cause problems!

This where **image digests** method come to the rescue.

This method makes all images get a *cryptographic content hash*.

```bash
$ docker image pull alpine
Using default tag: latest
latest: Pulling from library/alpine
cbdbe7a5bc2a: Pull complete
Digest: sha256:9a839e63da...9ea4fb9a54
Status: Downloaded newer image for alpine:latest
docker.io/library/alpine:latest

$ docker image ls --digests alpine
REPOSITORY 	TAG			DIGEST							IMAGE ID		CREATED		SIZE
alpine     	latest 		sha256:9a839e63da...9ea4fb9a54 	f70734b6a266	2 days ago	5.61MB
```
The example output above shows the digest for the alpine image as `sha256:9a839e63da...9ea4fb9a54`.


When no longer need an image on our Docker host, we can delete it with the `docker image rm` command.

Deleting an image will remove the image and all its layers from your Docker host. However, if an image layer is shared by more than one image, that layer will not be deleted until all images that reference it have been deleted.

The following example deletes an image by its ID.
```bash
$ docker image rm 02674b9cb179
Untagged: alpine@sha256:c0537ff6a5218...c0a7726c88e2bb7584dc96
Deleted: sha256:02674b9cb179d57...31ba0abff0c2bf5ceca5bad72cd9
Deleted: sha256:e154057080f4063...2a0d13823bab1be5b86926c6f860
```

### Docker images - The commands
Let's remind ourselves of the major commands we use to work with Docker images.

- **`docker image pull`**: is the command to download images. We pull images from repositories inside of
remote registries. By default, images will be pulled from repositories on Docker Hub. This command
will pull the image tagged as latest from the alpine repository on Docker Hub: docker image pull
alpine:latest.

- **`docker image ls`**: lists all of the images stored in your Docker host’s local image cache. To see the SHA256 digests of images add the **--digests** ﬂag.

- **`docker image inspect`**: is a thing of beauty! It gives you all of the glorious details of an image — layer data and metadata.

- **`docker image rm`**: is the command to delete images. You cannot delete an image that is associated with a container in the running (Up) or stopped (Exited) states.

## Docker containers
In this part we're going to get into containers.
And as usual we'll split this chapter into three sections:
- The TLDR
- The deep dive
- The commands

### Docker containers - The TLDR
A container is the runtime instance of an image. they're so faster and lightweight because they share the OS/kernel with the host they're running on. We can start one or more containers from a single image

<br>
<img src="./assets/container.png" alt="container">
</br>

The simplest way to start a container is with the `docker container run` command, but its most basic form you tell it an image to use and a app to run: `docker container run <image> <app>`. The following command will start an *Ubuntu Linux* container running the *Bash shell* as its app.
```bash
$ docker container run -it ubuntu /bin/bash
```

The `-it` flag will connect your current terminal window to the container's shell.
Containers run until the app they are executing exits. In the previous examples, the Linux container will exit when the Bash shell exits.

You can manually stop a running container with the `docker container stop` command.

### Docker containers - The deep dive
The first things we'll cover here are the fundamental differences between a container and a VM.
Anyway, Let's start with a scenario, let's assume a requirement where your business has a single physical server that needs to run 4 business applications.
In the VM model, The physical server is powered on and the hypervisor boots. Once booted, the hypervisor lays claim to all physical resources on the system such as CPU, RAM, ROM, and NICs. It then carves these hardware resources into virtual versions that look smell and feel exactly like the real thing. It then packages them into a software construct called a virtual machine (VM). We take those VMs and install an operating system and application on each one. So the scenario in that model will look like

<br>
<img src="./assets/vm-scenario.png" alt="VM Scenario">
</br>

Things are a bit different in the container model.
The server is powered on and the OS boots. the OS claims all hardware resources. On top of the OS, we install a container engine such as Docker. The container engine then takes OS resources such as the *process tree*, the *filesystem*, and the *network stack*, anc carves them into isolated constructs called containers. Each container looks smells and feels just like a real OS. Inside of each container we run an application. So the scenario will look like

<br>
<img src="./assets/container-scenario.png" alt="Container Scenario">
</br>

At a high level, hypervisors perform **hardware virtualization** — they carve up physical hardware resources into virtual versions called VMs. On the other hand, containers perform **OS virtualization** — they carve OS resources into virtual versions called containers.

As a result, The VM model carves **low-level hardware resources** into VMs. Each VM is a software construct containing virtual CPUs, virtual RAm, virtual disks etc.As such every VM needs its own OS to manage those virtual resources.
The container model has a single OS/kernel running on the host. It's possible to run tens or hunderds of containers on a single host with every container sharing that single OS/kernel.
Another thing to consider is application start times. As a container isn't a full-blown OS, it starts **much faster** than a VM.

Well, one thing that's not so great about the container model is **security**. Out of the box, containers are less secure and provide less workload isolation than VMs.

Now, let's play around with some containers.
The simplest way to start a container is with the `docker container run` command.
The following command starts a simple container that will run a containerized version of Ubuntu Linux.
```bash
$ docker container run -it ubuntu:latest /bin/bash
Unable to find image 'ubuntu:latest' locally
latest: Pulling from library/ubuntu
d51af753c3d3: Pull complete
fc878cd0a91c: Pull complete
6154df8ff988: Pull complete
fee5db0ff82f: Pull complete
Digest: sha256:747d2dbbaaee995098c9792d99bd333c6783ce56150d1b11e333bbceed5c54d7
Status: Downloaded newer image for ubuntu:latest
root@50949b614477:/#
```

When we started the Ubuntu container in the above example, we told it to run *Bash shell*. This makes the Bash shell the **one and only process running inside of the container**.
If you're logged on to the container and type exit, you'll terminate the Bash process and the container will exit (terminate). This is because a container cannot exist without its designated main process. So **killing the main process in the container will kill the container**.

Press *Ctrl-PQ* to exit the container without terminating its main process.

You can use the `docker container ls` command to list all the running containers in you system.

```bash
$ docker container ls
CNTNR ID IMAGE               COMMAND        CREATED         STATUS          NAMES
509...74 ubuntu:latest       /bin/bash      6 mins          Up 6mins        sick_montalcini
```

This container is still running and you can re-attach your terminal to it with the `docker container exec` command.
```bash
$ docker container exec -it 50949b614474 bash
root@50949b614477:/#
```

You can stop and delete a container using the following two commands.
```bash
$ docker container stop 50949b614474
50949b614474

$ docker container rm 50949b614474
50949b614474
```

Containers can save data, If you write some data in a running container and then you stopped it, then you restart it again, the data will still there, but even if that illustrates the persistent nature of containers, it's important to understand two things:
1. The data created is stored on the Docker hosts local filesystem. If the docker host fails, the data will be lost.
2. Containers are designed to be immutable objects and it's not a good practice to write data to them.

For these reasons, Docker provides *volumes* that exist separately from the container, but can be mounted into the container at runtime.

### Docker containers - The commands
- **`docker container run`**: is the command used to start new containers.

- **`Ctrl-PQ`**: will detach your shell from the terminal of a container and leave the container running (UP) in the background.

- **`docker container ls`**: lists all containers in the running (UP) state. If you add the *-a* ﬂag you will also see containers in the stopped (Exited) state.

- **`docker container exec`**: runs a new process inside of a running container. It’s useful for attaching the shell of your Docker host to a terminal inside of a running container.

- **`docker container stop`**: will stop a running container and put it in the Exited (0) state.

- **`docker container start`**: will restart a stopped (Exited) container.

- **`docker container rm`**: will delete a stopped container.
- **`docker container inspect`**: will show you detailed conﬁguration and runtime information about a
container. It accepts container names and container IDs as its main argument.

## Containerizing an app
Docker is all about taking applications and running them in containers.

The process of taking an application and configuring it to run as a container is called "**containerizing**".

In this chapter, we'll walk through the process of containerizing a simple linux-based web application.
We'll split this chapter into the usual three parts:
- The TLDR
- The deep dive
- The commands

Let's containerize an app!

### Containerizing an app - The TLDR
The process of containerizing an app looks like this:
1. Start with your application code and dependencies
2. Create a Dockerﬁle that describes your app, its dependencies, and how to run it
3. Feed the Dockerﬁle into the docker image build command
4. Push the new image to a registry (optional)
5. Run container from the image

### Containerizing an app - The deep dive
This chapter walks through the process of containerizing a simple Node.js web app.

We'll complete the following high-level steps:
- Clone the repo to get the app code
- Inspect the Dockerﬁle
- Containerize the app
- Run the app

So, let's get in!
#### Getting the application code
The application used in this example is available on Github at `https://github.com/nigelpoulton/psweb.git`
Clone the app from github.
```bash
$ git clone https://github.com/nigelpoulton/psweb.git
```

move to the app directory

```bash
$ cd psweb
$ ls -l
total 28
-rw-r--r-- 1 root root 341 Sep 29 16:26 app.js
-rw-r--r-- 1 root root 216 Sep 29 16:26 circle.yml
-rw-r--r-- 1 root root 338 Sep 29 16:26 Dockerfile
-rw-r--r-- 1 root root 421 Sep 29 16:26 package.json
-rw-r--r-- 1 root root 370 Sep 29 16:26 README.md
drwxr-xr-x 2 root root 4096 Sep 29 16:26 test
drwxr-xr-x 2 root root 4096 Sep 29 16:26 views
```

Now that we have the app code, let's look at its Dockerfile.

#### Inspecting the Dockerfile
A **Dockerfile** is the starting point for creating a container image, it describes an application and tells Docker how to build it into an image.

Let's look at the contents of the Dockerfile.
```bash
$ cat Dockerfile
FROM alpine
LABEL maintainer="nigelpoulton@hotmail.com"
RUN apk add --update nodejs nodejs-npm
COPY . /src
WORKDIR /src
RUN npm install
EXPOSE 8080
ENTRYPOINT ["node", "./app.js"]
```

At a high-level, the Dockerfile says: Start with alpine image, make a note that "nigelpoulton@hotmail.com" is the maintainer, install Node.js and NPM, copy everthing in the build context to the /src directory in the image, set the working directory as /src, install depedencies, document the app's network port, and set app.js as the default application to run.

#### Containerize the app/build the image
So, let's build the image!
The following command will build a new image called web:latestl. The period (.) at the end of the command tells docker to use shell's current working directory as the *build context*.
```bash
$ docker image build -t web:latest .
```

Check that the image exists in your Docker host's local repository.
```bash
$ docker image ls
REPO          TAG         IMAGE ID            CREATED            SIZE
web           latest      fc69fdc4c18e        10 seconds ago     81.5MB
```

Congratulations, the app is containerized!

#### Run the app
The containerized application is a web server that listens on TCP port 8080.
The following command will start a new container called c1 based on the web:latest image you just created. It maps port 80 on the docker host, to port 8080 inside the container.

```bash
$ docker container run -d --name c1 \
-p 80:8080 \
web:latest
```

Check that the container is running and verify the port mapping.
```bash
$ docker container ls
ID               IMAGE          COMMAND            STATUS          PORTS                   NAMES
49..             web:latest     "node ./app.js"    UP 6 secs       0.0.0.0:80->8080/tcp    c1
```

Congratualtions!, the app container is running. Note that port 80 is mapped, on all host interfaces (0.0.0.0:8080).

Open a web browser and point it to the DNS name or IP address of the host that the container is running on.
and you'll see the web page.


### Containerizing an app - The commands
- **`docker image build`**: is the command that reads a Dockerﬁle and containerizes an application.
- The **`FROM`**: instruction in a Dockerﬁle speciﬁes the base image for the new image you will build.
- The **`RUN`**: instruction in a Dockerﬁle allows you to run commands inside the image. Each RUN instruction
creates a single new layer.
- The **`COPY`**: instruction in a Dockerﬁle adds ﬁles into the image as a new layer. It is common to use the COPY instruction to copy your application code into an image.
- The **`EXPOSE`**: instruction in a Dockerﬁle documents the network port that the application uses.
- The **`ENTRYPOINT`**: instruction in a Dockerﬁle sets the default application to run when the image is started as a container.

## Docker Compose
**Docker Compose** is a tool that deploys and manages multi-container applications on Docker nodes running in ***single-engine mode***.

In this chapter, we'll  look at how to deploy multi-container applications using Docker Compose.

We'll split this chapter into the usual three parts:
- The TLDR
- The deep dive
- The commands

### Docker Compose - The TLDR
Modern cloud-native apps are made of multiple smaller services that interact to form a useful app. We call this pattern "microservices". A simple example might be an app with following seven services:
- Web front-end
- Ordering
- Catalog
- Back-end
- logging
- Authentication
- Authorization

Deploying and managing lots of small microservices like these can be hard. This is where *Docker Compose* comes in to play.

So, Docker Compose lets you describe an entire app in a single declarative configuration file, and deploy it with a single command.

Once the app is *deployed*, you can manage its entire lifecycle with a simple set of commands.

### Docker Compose - The Deep Dive
#### Compose background
In the beginning was *Fig*. Fig was a powerfull tool, created by *Orchard* company, and it was the best way to manage multi-container Docker apps. It was a Python tool that sat on top of Docker, and let you define entire mutli-container apps in a single YAML file. You could then deploy and manage the lifecycle of the app with the `fig` command-line tool.

Behind the scenes, Fig would read the YAML file and use Docker to deploy and manage the app via the Docker API. It was a good thing.

In fact, it was so good, that Docker Inc. acquired *Orchard* and re-branded Fig as Docker Compose. The command-line tool was renamed from `fig` to `docker-compose`, and continues to be an external tool that gets bolted top of the Docker Engine.

As things stand today, Compose is still an external Python binary that you have to install on a Docker host. You define mutli-container (microservices) apps in a YAML file, pass the file to the `docker-compose` command line, and Compose deploys it via the Docker API.

#### Installing Compose
Now, we're going to install Docker Compose on a Linux-based OS, and it required two-steps.

**First**
Download the binary using the curl command
```bash
$ sudo curl -L \
"https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" \
-o /usr/local/bin/docker-compose
```

**Second**
Make the binary executable using chmod.
```bash
$ sudo chmod +x /usr/local/bin/docker-compose
```

Then you can verify the installation of Compose.
```bash
$ docker-compose --version
```

#### Compose files
Compose uses YAML files to define mutli-service applications. YAML is a subset of JSON, so you can also use JSON.

The default name for a Compose YAML file is `docker-compose.yml`.

The following example shows a very simple Compose file that defines a small Flask app with two microservices (web-fe and redis).
```yml
version: "3.8"
services:
	web-fe:
		build: .
		command: python app.py
		ports:
			- target: 5000
				published: 5000
		networks:
			- counter-net
		volumes:
			- type: volume
			source: counter-vol
			target: /code
	redis:
		image: "redis:alpine"
		networks:
			counter-net:
networks:
	counter-net:
volumes:
	counter-vol:
```

The first thing to note is that the file has 4 top-level keys:
- version
- services
- networks
- volumes

The `version` key is mandatory, and it's always the first line at the root of the file. and it defines the version of the Compose file format.

And it's important to note that the `version` key does not define the version of Docker Compose or the Docker Engine.

The top-level `services` key is where you define the different application microservices. This example defines two services; a web front-end called *web-fe*, and an in-memory database called *redis*. Compose will deploy each of these services as its own container.

The top-level `networks` key tells Docker to create new networks. By default, Compose will create bridge networks. These are single-host networks that can only connect containers on the same Docker host.

The top-level `volumes` key is where you tell Docker to create new volumes.
