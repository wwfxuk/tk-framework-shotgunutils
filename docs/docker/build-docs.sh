#!/bin/bash

#
# usage: build-docs.sh [OUTPUT_DIR]
#
# Create sphinx documentations when run from repository root.
#
# By default, the docs will be output to docs/_build relative to the
# repository's root folder. Pass in a custom folder
#

set -eu +f -o pipefail
shopt -s dotglob

PYTHON_ONLY_DIR=$(mktemp -d)
DOCS_DIR="${DOCS_DIR:-docs}"
API_RST_DIR="${PYTHON_ONLY_DIR}/${DOCS_DIR}/${API_RELATIVE_DIR:-api}"
OUTPUT_DIR=$(readlink --canonicalize-missing "${1:-docs/_build}")

STAT_FROM_DIR="${OUTPUT_DIR}"
[ -d OUTPUT_DIR ] || STAT_FROM_DIR="${DOCS_DIR}"
OUTPUT_OWN=$(stat -c '%u' "${STAT_FROM_DIR}"):$(stat -c '%g' "${STAT_FROM_DIR}")
OUTPUT_PERM=$(stat -c '%a' "${STAT_FROM_DIR}")

echo "
###
### ==== Running '${0}' from '$(pwd)' ====
###         Using docs (conf.py) from: '$(readlink --canonicalize ${DOCS_DIR})'
###  Setting up Python source code in: '${PYTHON_ONLY_DIR}'
### Temporary API (RST) sphinx-apidoc: '${API_RST_DIR}'
###            Final HTML docs output: '${OUTPUT_DIR}'
###
"

# Clean, create output folder and set permissions to match original docs owner
rm -rf "${OUTPUT_DIR}"/*
for NEW_DIR in $(mkdir -vp "${OUTPUT_DIR}" | sed 's/.*created directory .//; s/.$//')
do
    chown "${OUTPUT_OWN}" "${NEW_DIR}" &> /dev/null || echo '
Unable to set owner for "'${NEW_DIR}'" to be same as "'${STAT_FROM_DIR}'".
Please try again as root, e.g.

sudo chown "'${OUTPUT_OWN}'" "'${NEW_DIR}'"/*

'
done

# Copy only .py files, ensure leading folders have a __init__.py
find * -name '*.py' ! -path "${DOCS_DIR}/*" ! -ipath "test*/*" -printf "${PYTHON_ONLY_DIR}/%h\n" | xargs mkdir -p
find "${PYTHON_ONLY_DIR}"/* -type d -exec touch {}/__init__.py \; -printf 'Created %p/__init__.py\n'
find * -name '*.py' ! -path "${DOCS_DIR}/*" ! -ipath "test*/*" -exec cp -fv {} "${PYTHON_ONLY_DIR}"/{} \;
cp -rv '.travis.yml' "${DOCS_DIR}" "${PYTHON_ONLY_DIR}"

# -- Generate API docs first with dash so it matches existing folders/files --
cd "${PYTHON_ONLY_DIR}"
echo "---- Inside $(pwd) ----"
rm -rvf "__init__.py" test*/  # No
mkdir -vp "${API_RST_DIR}"
sphinx-apidoc -o "${API_RST_DIR}" --separate --no-toc .

# Replace - with _ so sphinx build can import modules
sed -i '/automodule:: / s/-/_/g' "${API_RST_DIR}"/*.rst

# Rename folder first before renaming .py files
for DASH_FOLDER in $(find -type d -name '*-*')
do
    mv -v "${DASH_FOLDER}" "${DASH_FOLDER//-/_}"
done
for DASH_PY_FILE in $(find -name '*-*.py')
do
    cp -v "${DASH_PY_FILE}" "${DASH_PY_FILE//-/_}"
done


# Generate HTML output and set permissions to match original docs owner
python - "${DOCS_DIR}" "${OUTPUT_DIR}" << EOF
# Same as sphinx_build, but patches _MockObject, sgtk
import re
import sys

from mock import MagicMock
from sphinx.cmd.build import main
try:
    import sphinx.ext.autodoc.mock as autodock_moc
except ImportError:
    import sphinx.ext.autodoc.importer as autodock_moc

import sgtk.platform.util
import sgtk.util.qt_importer


if __name__ == '__main__':
    for meth in ['__add__', '__sub__', '__mul__', '__matmul__', '__div__',
                '__truediv__', '__floordiv__', '__mod__', '__divmod__',
                '__lshift__', '__rshift__', '__and__', '__xor__',
                '__or__', '__pow__']:
        setattr(autodock_moc._MockObject, meth, MagicMock())
    sgtk.platform.util._get_current_bundle = MagicMock()
    sgtk.util.qt_importer.QtImporter = MagicMock()
    sys.argv[0] = re.sub(r'(-script\.pyw?|\.exe)?$', '', sys.argv[0])
    sys.exit(main())

EOF
cp -r "${API_RST_DIR}" "${OUTPUT_DIR}/_api"
chown --recursive "${OUTPUT_OWN}" "${OUTPUT_DIR}"/* &> /dev/null || echo '
Unable to set owner for generated HTML to be same as "'${STAT_FROM_DIR}'".
Please try again as root, e.g.

    sudo chown --recursive "'${OUTPUT_OWN}'" "'${OUTPUT_DIR}'"/*

'