#!/bin/bash

join_by() { local IFS="$1"; shift; echo "$*"; }

yaml() {
    python -c "import yaml;print(' '.join(str(x) for x in yaml.load(open('$1'),Loader=yaml.FullLoader)$2))"
}

VALUE=$(yaml ./openy.info.yml "['dependencies']")
echo ${VALUE}
