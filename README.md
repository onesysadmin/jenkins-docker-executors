# Run Jenkins builds that use docker

This is a docker image that contains Jenkins, and has the ability to run docker within docker or against a host docker server.


## Using a host docker server
    
To use a host docker server, you just need to bind mount /var/run/docker.sock into the container:

    docker run -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock --name jenkins-1 onesysadmin/jenkins-docker-executors

This will download, and then run Jenkins in a docker container - on port 8080. You must bind the docker socket into the container for the container to run as it will check this.  No special privilege is needed.

## Running docker server within docker

To run a docker server inside docker, you will need to run the container in privileged mode:

    docker run --privileged -p 8080:8080 --name jenkins-1 onesysadmin/jenkins-docker-executors

By default, the container will launch a docker server inside the container if it does not detect an existing socket file at `/var/run/docker.sock`.


## Storing Jenkins Data

If you wish to use a volume outside to store your workspace, you can by using bind mounting and setting the JENKINS_HOME directory. 

Also, you can create [data containers](http://docs.docker.io/use/working_with_volumes/) to store jenkins data, which should correspond to the JENKINS_HOME.  This image by default sets JENKINS_HOME to ```/var/jenkins```.  It can be overridden via the docker environment setting.

An example of using data containers would be something like:

    docker run --name JENKINS_DATA -v /var/jenkins busybox true
    docker run -d -v /var/run/docker.sock:/var/run/docker.sock --volumes-from JENKINS_DATA -p 8080:8080 --name jenkins-1 onesysadmin/jenkins-docker-executors

This will allow you to persist your jenkins data across container restarts.  In addition, you will also be able to attach the data container to make backups separately from the jenkins container.

__NOTE__

If you make use of the host's docker server to do all the work, it is recommended that you create the jenkins data directory in the host system to bind mount into jenkins docker container.  This will make running docker easier as you do not need to bind mount JENKINS_DATA data volume for every docker launch in order to access the workspace and other information.  Here's an example:

```
mkdir /var/jenkins
docker run -d -v /var/run/docker.sock:/var/run/docker.sock -v /var/jenkins:/var/jenkins -p 8080:8080 --name jenkins-1 onesysadmin/jenkins-docker-executors
```

## Jenkins User 

Jenkins runs as root user within the container.  By default, the root user home directory is set to /, but this has been overridden to be set to the same as JENKINS_HOME, which is ```/var/jenkins```.  This allows you to actually inject your own SSH keys, dockercfg file, and other OS-level config and authentication settings directly within the jenkins data volume so we can customize it separately should we need to.

## Caveats to Running Docker in Docker

You can run docker server within docker.  This will require creating ```/var/lib/docker``` as a data volume inside the container itself.

There are tradeoffs to running docker within docker.

1. Running docker server inside the container allows you to containerize and limit access to other host docker containers.  This is a secure way of running docker if you plan to do multi-tenant hosting of jenkins instances.

2. The downside to running docker inside docker is that the performance and speed will be drastically reduced.  If you use the host docker server to run containers, the performance is 50+% faster than running inside a docker within docker container. By using and accessing an external host docker system, we remove the need to use a data volume for storing internal docker host.  This actually speeds up the creation of docker images by over 50% since we're not using vfs but the host system's storage engine.

3. Additionally, please be aware that when you exit the docker container and remove the container, the data volume continues to exist.  This may take up an abnormal amount of space since you would assume that the data volume was cleared out after the container is stopped and removed. 
    To properly remove the data volume created by the container, we would need to issue the command ```docker rm -v```.  The -v flag will properly remove volumes created by the container.

4. Over time, you may experience issues where DND cannot launch docker server inside docker due to an error where there are no more loopback devices available.  This is caused by issues where docker server was not given time to shutdown properly before the container was stopped, which then does not release some mount points.  A restart of the host server is required in this case.
5. Certain plugins write out temp files into `/tmp` directory.  This directory is not accessible in other docker containers since this exists inside only the jenkins container.  It is suggested, if possible, to set the target location when generating these files so that they exist inside the workspace.

## Building/Running Docker Images Inside Jenkins Docker Container

If you wish to use docker in a build - you can. You can just use the `docker` command from a freestyle build, it will work just like you expected. Don't do anything crazy like try to run this thing itself inside docker, as then you end up in an inception like world and ultimate in limbo. http://inception.davepedu.com/ ;)

This works via the exellent work covered here https://github.com/jpetazzo/dind

## How to build it and run it for PlateCulture
`docker build .` (when inside of a folder with Dockerfile)

```
sudo docker run -d -p 8080:8080 -v /var/run/docker.sock:/var/run/docker.sock \
  -v /home/core/jenkins:/var/jenkins_home -e "JENKINS_HOME=/var/jenkins_home" \
  --name jenkins --restart always --privileged #{container_id}
```
