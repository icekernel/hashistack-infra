# Packer build scripts for picksups.click AMIs

## Requirements

Ensure you have packer and ansible installed

```console
cd $(git rev-parse --show-toplevel)  # Go to project root.
pkenv install 1.8.2
pyenv install 3.10.2
```

```console
python -m venv venv
. venv/bin/activate
cd ansible
pip install -r requirements.txt
```

## Building a new AMI

Scripts have been written to make it easier to pass the correct
parameters to packer. They are named `<env>-<role>.sh` where env and role
are each the environment and role you wish to deploy to.

Eg. to build the production ami for the nodejs backend AMI use the following:

```console
./prod1-eliza.sh
```
