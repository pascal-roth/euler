FROM nvidia/cuda:11.2.0-base

RUN ln -fs /usr/share/zoneinfo/Europe/Zurich /etc/localtime
RUN ln -s /usr/local/cuda/compat/libcuda.so.1 /usr/lib/x86_64-linux-gnu/libcuda.so.1
RUN apt-get update ; DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
RUN apt-get update ; apt-get install -y software-properties-common
RUN apt-add-repository -y ppa:deadsnakes/ppa; exit 0
RUN add-apt-repository -y ppa:graphics-drivers/ppa; exit 0
RUN apt-get update ; exit 0
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python3.8 python3.8-dev python3.8-venv openscad libgomp1 git g++ bc

RUN mkdir -p /app/shared/
WORKDIR /app

RUN python3.8 -m venv /app/venv/
ENV PATH="/app/venv/bin:$PATH"

COPY docker_run.sh /app/

# Install dependencies
RUN pip install torch==1.13.0 torchvision==0.14.0 torchaudio==0.13.0 --extra-index-url https://download.pytorch.org/whl/cu116
RUN pip install opencv-python
RUN pip install pypose==0.2.1
RUN pip install open3d
RUN pip install tqdm
RUN pip install trimesh
RUN pip install warp-lang
RUN pip install wandb
RUN pip install networkx

CMD cd /app && ./docker_run.sh
