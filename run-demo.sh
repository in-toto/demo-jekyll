#! /bin/bash

###############################################################################
# <Program Name>
#  run-demo.sh
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
#   with jekyll, using the in-toto grafeas client to provide integrity and
#   authenticity verification.
#   The supply chain consists of the following steps:
#
#     1. Tag the release of the jekyll project using git
#     2. Build the static webpages with jekyll
#     3. Test the build with htmlproofer
#     4. Package the build into a docker image
#
#  The script runs the commands described in the README.md, i.e.
#  publish a supply chain layout on the grafeas demo server, execute the
#  supply chain commands, producing link metadata for each step and publishing
#  it on the grafeas server and eventually fetching all the metadata to verify
#  it using in-toto's final product verification.
#
#
# <Requirements>
#   The demo requires the following software to be installed on your system
#     - Git
#     - Python2.7
#     - Ruby (packages: jekyll, htmlproofer)
#     - Docker
#     - in-toto grafeas client
#
#    Install the in-toto grafeas client from the submodule in this repo,
#    ideally in a python virtualenvironment, e.g.:
#
#    # Clone this repo recursively and change into it
#    $ git clone https://github.com/in-toto/demo-jekyll.git --recursive
#    $ cd demo-jekyll
#
#    $ mkvirtualenv grafeas-demo
#    $ (grafeas-demo) pip install -e repos/totoify-grafeas
#
# <Usage>
#    # Run supply chain steps and verify (passes)
#    $ ./run-demo.sh
#
#    # Run supply chain steps, sneak in malicious code and verify (fails)
#    $ ./run-demo.sh attack
#
###############################################################################

# Each demo is namespaced on the grafeas server using a pseudo unique project
# id, to avoid metadata collisions. (Note: this is not safe but convenient)
project_id="demo-$(date +%s)"

f_key="$(pwd)/metadata/functionary"
o_pubkey="$(pwd)/metadata/owner.pub"
layout="$(pwd)/metadata/root.layout"
docker_image="jekyll-demo"
target="http://grafeas.nyu.wtf/v1alpha1/projects/${project_id}"
demo_project_url="https://github.com/in-toto/demo-project-jekyll.git"
demo_project_name="project"

if [[ ! (-e ${f_key} && -e ${o_pubkey} && -e ${layout}) ]]; then
  echo "Error: Could not find all required metadata files."
  echo "You should run this script from inside its repo."
  exit 1
fi

# Cache in-toto so we don't always have to clone
if [ -d ${demo_project_name} ]; then
  echo "Error: The script needs to re-clone the demo project."
  echo "Please remove the existing demo project directory!"
  echo "    rm -rf ${demo_project_name}"
  exit 1
fi

# Publish the prepared in-toto layout metadata as operation on grafeas server
grafeas-load --id $project_id --layout $layout

# Clone and change into demo project repo,
# i.e. the project whose supply chain we secure
git clone ${demo_project_url} ${demo_project_name}
cd ${demo_project_name}

# Run supply chaincommands
# generating and publishing link metadata on grafeas server

# Step 1. -- Tag the project with git
grafeas-run --id $project_id -k $f_key --name tag --products . -- git tag v1.0

# If the script is run with attack argument we will sneak in malicious code
# which will make the verification fail.
if [ "$1" = "attack" ]; then
  git checkout compromise
fi

# Step 2. -- Build static web pages with jekyll
grafeas-run --id $project_id -k $f_key --name build \
    --materials . --products _site -- jekyll build

# Step 3. -- Test static web pages with htmlproofer
grafeas-run --id $project_id -k $f_key --name test \
    --materials . -- htmlproofer _site/

# Step 4. -- Create a docker image that can serve the website
grafeas-run --id $project_id -k $f_key --name dockerize \
    --materials _site -- docker build -t ${docker_image} .


# Fetch layout (operation) and link (occurrences) metadata from grafeas server
# and run in-toto final product verification
grafeas-verify --id $project_id --key $o_pubkey
failed=$?

echo -e "\n\n"
echo "You can retrieve the demo metadata from the grafeas server manually at:"
echo "${target}/operations"
echo "${target}/notes"
echo "${target}/occurrences"

echo -e "\n\n"
if [ $failed -ne 0 ]; then
  echo "in-toto verification detected a supply chain compromise!"
  echo "Just for fun, you should spin up a container and take a quick look! ;)"
fi
echo "Deploy:"
echo "    docker run --rm -d -p 4001:80 -t ${docker_image}"
echo "Go to:"
echo "    http://localhost:4001"
echo "Remove docker container/image:"
echo "    docker stop \$(docker ps --filter \"ancestor=${docker_image}\" -q)"
echo "    docker rmi ${docker_image} -f"