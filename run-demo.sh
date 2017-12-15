#! /bin/bash

# Installation Requirements
# Python (virtualenvwrapper, totoify-grafeas)
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

# Let's create a new grafeas id each time we run the script so we
# won't get any "foobar already exists" errors.
project_id="kek-$(date +%s)"

echo "Starting grafeas demo..."
echo "Project ID: ${project_id}"

grafeas-load --id $project_id --layout $layout

git clone https://github.com/in-toto/${git_demo_name}.git
cd ${git_demo_name}

grafeas-run --id $project_id -k $key --name tag --products . -- git tag v1.0
grafeas-run --id $project_id -k $key --name build --materials . --products _site -- jekyll build
grafeas-run --id $project_id -k $key --name test --materials . -- htmlproofer _site/
grafeas-run --id $project_id -k $key --name dockerize --materials _site -- docker build -t ${docker_image_name} .

# Let's do this in a temp subdir because we will download all the metadata from
# grafeas into cwd
mkdir tmp-${project_id}
cd tmp-${project_id}
grafeas-verify --id $project_id --key $layout_key
