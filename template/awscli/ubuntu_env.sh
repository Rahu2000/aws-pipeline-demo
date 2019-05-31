# OS type Check
GIT="$(git --version 2> /dev/null | awk '{print $1}')"
PYTHON="$(python3 --version 2> /dev/null | awk '{print $1}')"
PIP="$(pip3 --version 2> /dev/null | awk '{print $1}')"
CURL="$(curl --version 2> /dev/null | awk '{print $1}' | cut -d ' ' -f 1 | head -1 )"
AWS_CLI="$(aws --version 2> /dev/null | awk '{print $1}' | cut -d '/' -f 1 )"
JQ="$(jq --version 2> /dev/null | awk '{print $1}' | cut -d '-' -f 1)"

sudo apt update

# git install
if [ "$GIT" != "git" ]; then
    echo 'install git...'
    sudo apt -y install git
else
    echo 'git is already installed'
fi

# python3 install
if [ "$PYTHON" != "Python" ]; then
    echo 'install python3...'
    sudo apt -y install python3 python3-distutils
else
    echo 'python3 is already installed'
fi

# curl install
if [ "$CURL" != "curl" ]; then
    echo 'install curl...'
    sudo apt -y install curl
else
    echo 'curl is already installed'
fi

# pip3 install
if [ "$PIP" != "pip" ]; then
    echo 'install pip3...'
    sudo apt -y install python3-distutils python3-testresources
    curl -O https://bootstrap.pypa.io/get-pip.py
    python3 get-pip.py --user
    eval echo "~$USER"
    source .profile
else
    echo 'pip3 is already installed'
fi

# AWS CLI instll
if [ "$AWS_CLI" != "aws-cli" ]; then
    echo 'install aws-cli...'
    pip3 install awscli --upgrade --user
else
    echo 'aws-cli is already installed'
fi

# jq install
if [ "$JQ" != "jq" ]; then
    echo 'install aws-cli...'
    sudo apt -y install jq
else
    echo 'jq is already installed'
fi

exit 0