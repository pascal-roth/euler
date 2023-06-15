# Run Docker Container on ETHZ Euler Cluster

## Overview
This work contains a collection of scripts that enable users to run jobs on euler using a Docker image that is executed as a Singularity file. The scripts handle the building of the Docker image, allowing the user to define the exact packages and dependencies needed for the job within the Dockerfile. The scripts also handle the conversion of the Docker image to a Singularity file. 

## Deployment 


NOTE: When starting a job, please keep the resources in mind. A normal GPU node has 8 GPUs with 512GB RAM and 920GB Scratch Memory. 
When only one GPU is used, in theory, you have 64GB of RAM and 115GB of Scratch memory for an equal distribution. 
In the case, you request much more RAM, your job will be scheduled later as less some GPUs on the node may not be usable due to insufficient RAM capacity. 

### Pre-Requists
- NVIDIA Container Toolkit, can be installed [here](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#installation-guide)

Install [GO]()

´´´bash
export VERSION=1.13 OS=linux ARCH=amd64 && \ 
  wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz && \ # Downloads the required Go package
  sudo tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz && \ # Extracts the archive
  rm go$VERSION.$OS-$ARCH.tar.gz    # Deletes the ``tar`` file
´´´

´´´
echo 'export PATH=/usr/local/go/bin:$PATH' >> ~/.bashrc && \
  source ~/.bashrc
´´´

Install [Singularity]()

´´´
export VERSION=3.7.4 && \
    mkdir -p $GOPATH/src/github.com/sylabs && \
    cd $GOPATH/src/github.com/sylabs && \
    wget https://github.com/sylabs/singularity/releases/download/v${VERSION}/singularity-${VERSION}.tar.gz && \
    tar -xzf singularity-${VERSION}.tar.gz && \
    cd ./singularity && \
    ./mconfig
´´´

´´´
./mconfig && \
    make -C builddir && \
    sudo make -C builddir install
´´´