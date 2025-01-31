# base

This role could be refactored into base-controller and base-host. See the
problem with [./hashistack-client.yml](./hashistack-client.yml)

```yaml
---
- name: install hashistack packages
  hosts: docker, eliza, nginx
  tasks:
    - import_tasks: ./tasks/hashistack-packages.yml

- name: consul base configuration
  hosts: docker, eliza, nginx
  tasks:
    - import_tasks: ./tasks/consul-base.yml

- name: consul client configuration
  hosts: docker, eliza, nginx
```

We're not really using roles for simpler ansible syntax, but .. if you want
you can use roles.
