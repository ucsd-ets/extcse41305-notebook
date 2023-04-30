# 1) choose base container
# generally use the most recent tag

# base notebook, contains Jupyter and relevant tools
# See https://github.com/ucsd-ets/datahub-docker-stack/wiki/Stable-Tag
# for a list of the most current containers we maintain
ARG BASE_CONTAINER=ucsdets/datahub-base-notebook:2023.2-stable

FROM $BASE_CONTAINER

LABEL maintainer="UC San Diego ITS/ETS <ets-consult@ucsd.edu>"

# 2) change to root to install packages
USER root

COPY run_jupyter.sh /
RUN chmod +x /run_jupyter.sh

# RUN apt-get -y install htop
# RUN pip install --no-cache-dir \
#     keras==2.6.0 \
#     tensorflow==2.8 \
#     tensorflow-gpu==2.8 && \
#     fix-permissions $CONDA_DIR && \
#     fix-permissions /home/$NB_USER

# Install octave
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get -yq dist-upgrade \
    && apt-get install -yq --no-install-recommends \
    octave \
    && rm -rf /var/lib/apt/lists/*

# 3) install packages using notebook user
RUN conda install nb_conda_kernels
ARG KERNEL=cse41305
ENV CONDA_PREFIX=/opt/conda/envs/${KERNEL}
COPY env.yml /tmp
#ENV CONDA_CUDA_OVERRIDE="11.2"
RUN conda env create --file /tmp/env.yml && \
    eval "$(conda shell.bash hook)" && \
    conda activate ${KERNEL} && \
    mkdir -p $CONDA_PREFIX/etc/conda/activate.d && \
    CUDNN_PATH=$(dirname $(python -c "import nvidia.cudnn;print(nvidia.cudnn.__file__)")) && \
    echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CONDA_PREFIX/lib/:$CUDNN_PATH/lib' > $CONDA_PREFIX/etc/conda/activate.d/env_vars.sh && \
    python -m ipykernel install --name=${KERNEL} && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER
ENV CUDNN_PATH=/opt/conda/envs/cse41305/lib/python3.9/site-packages/nvidia/cudnn
# Install gnuplot & required dependencies 
RUN apt-get update -y && \
    apt-get -qq install -y --no-install-recommends gnuplot \
    apt-get -qq install -y --no-install-recommends libfltk1.3-dev 
USER jovyan

# RUN conda install -y scikit-learn

# RUN pip install --no-cache-dir networkx scipy

# Override command to disable running jupyter notebook at launch
# CMD ["/bin/bash"]
