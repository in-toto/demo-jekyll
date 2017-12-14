#! /bin/bash

# Installation Requirements
# Python (virtualenvwrapper, in-toto)
# Ruby (jekyll, htmlproofer)
# Docker

# mkvirtualenv in-toto

key="$(pwd)/metadata/functionary"
layout_key="$(pwd)/metadata/owner.pub"
layout="$(pwd)/metadata/root.layout"
git_demo_name="demo-project-jekyll"
docker_image_name="jekyll-demo"


# Cache in-toto so we don't always have to clone
if [ -d ${git_demo_name} ]; then
  echo "Remove demo project first:"
  echo "    rm -rf ${git_demo_name}"
  exit 1
fi

git clone https://github.com/lukpueh/${git_demo_name}.git
cd ${git_demo_name}

in-toto-run -n tag -k $key -p . -- git tag v1.0

# Sneak in bad code
if [ "$1" = "attack" ]; then
  git checkout compromise
fi

in-toto-run -n build -k $key -m . -p _site -- jekyll build
in-toto-run -n test -k $key -m . -- htmlproofer _site/
in-toto-run -n dockerize -k $key -m _site -- docker build -t ${docker_image_name} .

in-toto-verify -k $layout_key -l $layout

if [ $? -eq 0 ]; then
  echo -e "\n\n"
  echo "You can deploy your container using:"
  echo "    docker run --rm -d -p 4001:80 -t ${docker_image_name}"
  echo "The website will be available at:"
  echo "    https://localhost:4001"
  echo "Stop docker container and remove image with:"
  echo "    docker stop \$(docker ps --filter \"ancestor=${docker_image_name}\" -q)"
  echo "    docker rmi ${docker_image_name} -f"
fi

