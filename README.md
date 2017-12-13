# in-toto jekyll demo

Metadata and scripts to secure a basic jekyll supply chain with in-toto and
grafeas.

## Basic in-toto demo

```shell
# Create virtual environment, e.g.:
mkvirtualenv jekyll-in-toto-demo

# Install in-toto
pip install in-toto

# Clone this repo
https://github.com/lukpueh/demo-jekyll.git
cd demo-jekyll

# Run demo script
./run-demo.sh

# Check output
```

## in-totoized grafeas demo
```shell
# Create virtual environment, e.g.:
mkvirtualenv jekyll-grafeas

# Install grafeas fork develop mode (the setup.py needs some fixing)
git clone https://github.com/in-toto/totoify-grafeas --recursive
cd totoify-grafeas
pip install -e .
cd ..

# Clone this repo
git clone https://github.com/lukpueh/demo-jekyll.git
cd demo-jekyll

# Run demo
./run-grafeas-demo.sh

# Check output
```


## TODO:
- Write this document
- Clean up scripts