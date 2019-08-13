FROM centos:7

#
# From REPOSITORY ROOT, run:
#
#   (Run once FIRST) Create "local/tk-framework-shotgunutils-docs" image to build docs with:
#
#       docker build --rm -t local/tk-framework-shotgunutils-docs docs/docker
#
#   (Run when you update docs) Build docs into "docs/_build", deletes existing:
#
#       docker run --rm -it -v $(pwd):/repo local/tk-framework-shotgunutils-docs
#
#   By default, the settings/outputs are as (relative to REPOSITORY root):
#   - HTML output folder: docs/_build
#   - Folder with Sphinx conf.py: docs
#       - Sub-folder to generate API .rst using sphinx-apidoc: api
#
# Advanced:
#
#   Setting custom docs, API (generated .rst) and HTML output directory
#   RELATIVE to repository root:
#
#       docker run --rm -v $(pwd):/repo \
#           -e DOCS_DIR=docs/sphinx \
#           -e API_RELATIVE_DIR=apidoc \
#           local/tk-framework-shotgunutils-docs \
#           .github/html
#
#   Run image interactively as new container (enter bash shell):
#
#       docker run --rm -v $(pwd):/repo \
#           -it \
#           --entrypoint bash \
#           local/tk-framework-shotgunutils-docs
#

WORKDIR /usr/local/bin/
COPY build-docs.sh .

# Install in PARALLEL [using]:
# - PyQt4 [yum]
# - tk-core python libs (also sets build-docs.sh as executable)
# - pip [official get-pip.py] THEN sphinx, including ReadTheDocs theme [pip]
RUN yum install -y pyqt4 \
    & curl -L https://bootstrap.pypa.io/get-pip.py | python - \
    && pip install mock PyYAML sphinx-rtd-theme \
    & curl -LO 'https://raw.githubusercontent.com/wwfxuk/tk-doc-generator/v1.0.0%2Bwwfx.0.4.1/scripts/get-tk-core-packages.sh' \
    && chmod -v a+x * \
    && get-tk-core-packages.sh /usr/lib64/python2.7/site-packages \
    & wait

WORKDIR /repo
VOLUME /repo

# Docs folder with sphinx conf.py: docs (relative to /repo)
# Folder to generate API RST files into: api (relative to $DOCS_DIR)
ENV DOCS_DIR=docs
ENV API_RELATIVE_DIR=api

ENTRYPOINT build-docs.sh
CMD docs/_build
