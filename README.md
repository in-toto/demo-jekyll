# in-toto grafeas jekyll demo

This demo walks through a simple software supply chain for a website generated
with *jekyll* using [*in-toto*](https://in-toto.io) and
[*grafeas*](https://grafeas.io/) to provide integrity and authenticity
verification. The basic supply chain consists of the following steps:
1. Tag the release of the jekyll project using *git*
1. Build the static webpages with *jekyll*
1. Test the build with *htmlproofer*
1. Package the build into a *docker* image

In order to guarantee the integrity of the resulting final product the commands
required to perform these steps are wrapped with the in-toto-grafeas client.
As a consequence each command produces metadata. This metadata contains
information about the used files before and after a step command is executed
and is signed by a [key](metadata/functionary) and published on the grafeas
demo server as *occurrences*.

This occurrence metadata allows to verify that only the given steps were
performed and only by the authorized actors, according to a
[project definition](metadata/root.layout), which is also published on the
grafeas demo server as *operation*.


### Requirements
The demo requires the following software to be installed on your system: [Git](https://git-scm.com/), [Python 2.7](https://www.python.org/downloads/) ([virtualenvwrapper](http://virtualenvwrapper.readthedocs.io/en/latest/)), [Ruby](https://www.ruby-lang.org) ([jekyll](https://jekyllrb.com/), [HTMLproofer](https://github.com/gjtorikian/html-proofer)) and [Docker](https://www.docker.com).

### Demo commands
#### Prepare workspace
```shell
# Clone this repo recursively and change into it
git clone https://github.com/in-toto/demo-jekyll.git --recursive
cd demo-jekyll

# Create a python virtualenvironment, e.g.
mkvirtualenv supply-chain-demo

# Install in-toto-grafeas client in develop mode
pip install -e repos/totoify-grafeas

# Assign some variables to reduce typing effort
f_key="$(pwd)/metadata/functionary"
o_pubkey="$(pwd)/metadata/owner.pub"
layout="$(pwd)/metadata/root.layout"
docker_image="jekyll-demo"
project_id="demo-$(date +%s)"
target="http://grafeas.nyu.wtf/v1alpha1/projects/${project_id}"

# Clone the jekyll demo project repo and change into it
git clone https://github.com/in-toto/demo-project-jekyll.git project
cd project
```

#### Upload supply chain layout to grafeas server
```shell
grafeas-load -i $project_id -l $layout
```

#### Execute supply chain steps
Run supply chain steps while creating in-toto metadata and pushing it to the
grafeas server

##### Step 1. - Git tag the project
```shell
# 1. tag
grafeas-run -i $project_id -k $f_key -n tag -p . -- git tag v1.0
```

##### Step 2. - Build the sources with jekyll
```shell
grafeas-run -i $project_id -k $f_key -n build -m . -p _site -- jekyll build
```

##### Step 3. - Test the build with htmlproofer
```shell
grafeas-run -i $project_id -k $f_key -n test -m . -- htmlproofer _site/
```

##### Step 4. - Package the build with docker
```shell
grafeas-run -i $project_id -k $f_key -n dockerize -m _site -- docker build -t ${docker_image} .
```


#### Verify the supply chain
Verify supply chain using the project's metadata from the grafeas server
```shell
grafeas-verify -i $project_id -k $o_pubkey
```
By the way, you can check out all the metadata you generated on the grafeas
server using the following commands:
```shell
curl ${target}/operations
curl ${target}/occurrences
```

You can safely spin up the docker container and visit your website at
[http://localhost:4001](http://localhost:4001)
```shell
docker run --rm -d -p 4001:80 -t ${docker_image}
# Stop and remove container with
docker stop $(docker ps --filter "ancestor=${docker_image}" -q)
```

#### Attack supply chain (verification will fail)

First we have to remove the earlier created files from the demo project repo
and remove the build metadata from the grafeas server
```shell
git clean -fdx
curl -X "DELETE" ${target}/occurrences/build-b17688a6
```

Then we sneak in some malicious contents before the build step and rebuild
creating and publishing new metadata
```shell
echo "something really malicious" >> index.html
grafeas-run -i $project_id -k $f_key -n build -m . -p _site -- jekyll build
```

Now, if we run verification it will fail because the `index.html` file that
went into the `build` step doesn't match the file that came out of the
`tag` step, which means the sneaky malicious code insertion was detected.
```shell
grafeas-verify -i $project_id -k $o_pubkey
```

#### Cleanup
Before you run the demo again you should remove the `project` directory. Also
make sure to update the `project_id` and `target` variable that you assigned
in the beginning, so that you don't get "XYZ already exists on the grafeas
server" errors.



### Demo script
There is a demo script that runs above commands in two flavors. Just run
one of the following commands from within this repo and make sure that you
have the in-toto grafeas client installed.

```shell
# Publishes layout, runs supply chain commands generating/publishing metadata
# and verifies the final product (passing verification)
./run-demo.sh
```

```shell
# Publishes layout, runs supply chain commands generating/publishing metadata,
# sneaks in malicious content between the tag and build step and verifies
# the final product (failing verification)
./run-demo.sh attack
```
