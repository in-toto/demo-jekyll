#! /bin/bash

###############################################################################
# <Program Name>
#  run-demo-vanilla.sh
#
# <Author>
#  Lukas Puehringer <lukas.puehringer@nyu.edu>
#
# <Started>
#     December 11, 2017
#
# <Copyright>
#   See LICENSE for licensing information.
#
# <Purpose>
#   Runs all commands of a simple software supply chain for a website generated
#   with jekyll, using in-toto to provide integrity and authenticity
#   verification. The supply chain consists of the following steps:
#
#     1. Tag the release of the jekyll project using git
#     2. Build the static webpages with jekyll
#     3. Test the build with htmlproofer
#     4. Package the build into a docker image
#
#  Eventually, the supply chain is verified.
#
#  Note, the website that is created will claim that its secured with in-toto
#  AND Grafeas. Which is incorrect if it is created by running this script.
#  If you want to throw Grafeas in the mix, take a look at the instructions in
#  the README.md
#
# <Requirements>
#   The demo requires the following software to be installed on your system
#     - Git
#     - Python2.7 (packages: in-toto)
#     - Ruby (packages: jekyll, htmlproofer)
#     - Docker
#
#
# <Usage>
#    Run supply chain steps and verify (passes)
#   ./run-demo-vanilla.sh
#
#   Run supply chain steps, sneak in malicious code and verify (fails)
#   ./run-demo-vanilla.sh attack
###############################################################################


functionary_key="$(pwd)/metadata/functionary"
layout_pubkey="$(pwd)/metadata/owner.pub"
layout_path="$(pwd)/metadata/root.layout"
git_repo_name="demo-project-jekyll"
git_repo_url="https://github.com/in-toto/${git_repo_name}.git"
docker_image_name="jekyll-demo"

if [[ ! (-e ${functionary_key} && -e ${layout_pubkey} \
    && -e ${layout_pubkey}) ]]; then
  echo "Could not find all required metadata files."
  echo "You should run this script from inside its repo."
  exit 1
fi

if [ -d ${git_repo_name} ]; then
  echo "Remove demo project first:"
  echo "    rm -rf ${git_repo_name}"
  exit 1
fi

git clone ${git_repo_url}
cd ${git_repo_name}

in-toto-run -n tag -k $functionary_key -p . -- git tag v1.0

# Sneak in bad code
if [ "$1" = "attack" ]; then
  git checkout compromise
fi

in-toto-run -n build -k $functionary_key -m . -p _site -- jekyll build
in-toto-run -n test -k $functionary_key -m . -- htmlproofer _site/
in-toto-run -n dockerize -k $functionary_key -m _site -- docker build -t ${docker_image_name} .

in-toto-verify -k $layout_pubkey -l $layout_path

echo -e "\n\n"
echo "Deploy:"
echo "    docker run --rm -d -p 4001:80 -t ${docker_image_name}"
echo "Go to:"
echo "    http://localhost:4001"
echo "Remove docker container/image:"
echo "    docker stop \$(docker ps --filter \"ancestor=${docker_image_name}\" -q)"
echo "    docker rmi ${docker_image_name} -f"
