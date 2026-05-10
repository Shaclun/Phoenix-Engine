ARG IMAGE_NAME=debian
ARG IMAGE_TAG=bookworm-slim
ARG ARCHITECTURE=amd64

FROM ${ARCHITECTURE}/${IMAGE_NAME}:${IMAGE_TAG}

# update packages list
RUN apt-get update

# upgrade packages
RUN apt-get upgrade -y

# clear temporary files
RUN apt-get clean

# install g2o server dependencies
RUN apt-get install -y \
	curl \
    libssl3 \
    procps

# install common packages
RUN apt-get install -y \
	nano \
	unzip \
    jq \
    default-mysql-client 

# downloads recent server-linux-x64 package
RUN curl -s "https://gitlab.com/api/v4/projects/34553745/releases/" \
  | jq -r '.[0].assets.links[] | select(.name == "server-linux-x64") | .direct_asset_url' \
  | xargs -n1 curl -L -o server-linux-x64.zip

# unpack recent server executable  
RUN unzip server-linux-x64.zip && \
    mv server-linux-x64 g2o_server && \
    rm server-linux-x64.zip && \
	find g2o_server -mindepth 1 ! -name 'G2O_Server.x64' -exec rm -rf {} +

# copies root directory into g2o_server folder 
COPY . ./g2o_server