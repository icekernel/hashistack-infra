# Infra for icekernelcloud01.com

## Configuration

You will need the following:

```
brew install consul nomad cfssl tfenv pkenv pyenv
```

This repo uses the following:

```console
tfenv install 1.2.5
pkenv install 1.8.2
pyenv install 3.10.2
```

inside the `./ansible` directory:

```console
python -m venv venv
. venv/bin/activate
pip install -r requirements.txt
```

## Usage

If you have access to the state, execute inside the `./terraform` directory:

```console
terraform plan
```
