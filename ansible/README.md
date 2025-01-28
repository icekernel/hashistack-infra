# ansible

please check [galaxy-collections.list](galaxy-collections.list) for the right
versions of ansible galaxy collections being used here.

## try to pick up some ansible

this will ping all hosts

```console
ansible all -m ping
```

apply the eliza main play

```console
ansible-playbook plays/role/eliza/main.yml
```

## building vs developing

ansible is configured for running in a total of 3 different modes in this
[eliza-infra](https://github.com/Use-Prism/eliza-infra) repository.

- pull
- push
- packer

playbooks are mostly supposed to run in any of these modes, at least it is how
I am developing them.

the [`../packer/`](../packer/) directory playbooks pull plays from inside this
very ansible directory, and configuration is meant to be kept as close as
possible between the different ansible run environments.

Note that not every type of playbook should run in any one of these modes, but
they "should" be able to execute properly... especially useful for running
in check mode against instances.

### building

building is done in packer, go se [`../packer/`](../packer/)

### developing

- spin up a new stack with an instance that only has nginx answering on port 80.
- use ansible to remote control that box until it is fully built with ansible
- make sure new playbook runs a build with packer
- launch stack with new ami

todo: add molecule and virtualbox or containerd
