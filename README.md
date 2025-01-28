# Infra for prism1.click

## TODO

- [x] state on terraform cloud
- [ ] log-rotation for all backend services
- [ ] monitoring
  - [ ] instance metrics dashboard
  - [ ] app logs
  - [ ] metrics and log alarms
- [x] different TF Cloud workspaces for staging and prod
- [x] nomad ci/cd
- [ ] create a terraform system user on AWS for AWS key on TFC

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
