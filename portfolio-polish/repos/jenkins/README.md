# Jenkins + Ansible lab

Jenkinsfiles and Ansible content for a DevOps lab covering:

- **Infra** — `Jenkinsfile_infra` + `infra/`
- **Config** — `Jenkinsfile_config` + `config/`
- **RBAC** — `Jenkinsfile_rbac` + `rbac/`

## Usage

1. Create the credential IDs referenced in the Jenkinsfiles in your Jenkins controller
2. Point a Multibranch / Pipeline job at this repo
3. Run infra → config → rbac in that order unless your lab docs say otherwise

## Caution

Treat credential IDs and hostnames in playbooks as examples. Rotate anything that looks real before using against a live environment.
