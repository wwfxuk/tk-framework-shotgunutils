# docker run --rm -it -e COVERALLS_REPO_TOKEN -v $(pwd):/usr/local/src $(docker build --quiet tests/)
FROM python:2.7

RUN set -x \
    && pip install coverage coveralls \
    # install pyside - from https://stackoverflow.com/questions/24489588
    & apt-get update \
    && apt-get install -y libqt4-dev \
    & wait \
    && pip install PySide --no-index --find-links https://parkin.github.io/python-wheelhouse/ \
    # Travis CI servers use virtualenvs, so we need to finish the install by the following
    # && python ~/virtualenv/python${TRAVIS_PYTHON_VERSION}/bin/pyside_postinstall.py -install \
    && pyside_postinstall.py -install \
    && pip list

# Setup tk-core
ENV TK_CORE_PATH=/tmp/tk-core
WORKDIR ${TK_CORE_PATH}
RUN git clone https://github.com/shotgunsoftware/tk-core . \
    && git checkout master

# Mount code to here to run
WORKDIR /usr/local/src
VOLUME [ "/usr/local/src" ]

# Setup run_tests
RUN echo "${TK_CORE_PATH}/tests/run_tests.sh --test-root tests --with-coverage && coveralls" \
    > /usr/local/bin/entrypoint
ENTRYPOINT [ "/bin/bash", "/usr/local/bin/entrypoint" ]