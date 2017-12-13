# in-toto jekyll demo

Metadata and scripts to secure a basic jekyll supply chain with in-toto and
grafeas.

## Basic in-toto demo

```shell
# Create virtual environment, e.g.:
mkvirtualenv jekyll-in-toto-demo

# Install in-toto
pip install in-toto

# Run demo script
./run-demo.sh

# Check output
```

## in-totoized grafeas demo
```shell
# Create virtual environment, e.g.:
mkvirtualenv jekyll-grafeas

# install grafeas fork
pip install git+https://github.com/in-toto/totoify-grafeas

./run-grafeas-demo.sh

# Check output
```


## TODO:
- Write this document
- Clean up scripts