# Pull nivida cuda image
#   base: Includes the CUDA runtime (cudart)
#   runtime: Builds on the base and includes the CUDA math libraries, and NCCL. A runtime image that also includes cuDNN is available.
#   devel: Builds on the runtime and includes headers, development tools for building CUDA images. These images are particularly useful for multi-stage builds.
# if intended to compile CUDA code, use the devel image and make sure that the CUDA version matches the version used to compile pytorch (i.e. cu116 for nvidia/cuda:11.6.0)
# complete list of CUDA images https://gitlab.com/nvidia/container-images/cuda/blob/master/doc/supported-tags.md

FROM nvidia/cuda:11.7.0-cudnn8-devel-ubuntu20.04

RUN ln -fs /usr/share/zoneinfo/Europe/Zurich /etc/localtime
# RUN ln -s /usr/local/cuda/compat/libcuda.so.1 /usr/lib/x86_64-linux-gnu/libcuda.so.1
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
RUN pip install --verbose --no-cache-dir torch==1.13.0 torchvision==0.14.0 torchaudio==0.13.0 --extra-index-url https://download.pytorch.org/whl/cu117
RUN pip install --verbose --no-cache-dir opencv-python==4.5.4.60
RUN pip install --verbose --no-cache-dir pypose==0.2.1
RUN pip install --verbose --no-cache-dir open3d
RUN pip install --verbose --no-cache-dir tqdm
RUN pip install --verbose --no-cache-dir trimesh
RUN pip install --verbose --no-cache-dir warp-lang
RUN pip install --verbose --no-cache-dir wandb
RUN pip install --verbose --no-cache-dir networkx
RUN pip install --verbose --no-cache-dir 'git+https://github.com/facebookresearch/detectron2.git'

# install third party code with cuda compiled code (as example detectron2 and mask2former)
COPY third_party/mask2former /app/third_party/mask2former
RUN pip install --verbose --no-cache-dir -r /app/third_party/mask2former/requirements.txt
RUN chmod 777 '/usr/local/lib/python3.8/dist-packages'
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64/stubs/:$LD_LIBRARY_PATH
ENV FORCE_CUDA="1"
RUN python /app/third_party/mask2former/mask2former/modeling/pixel_decoder/ops/setup.py build install

CMD cd /app && ./docker_run.sh
