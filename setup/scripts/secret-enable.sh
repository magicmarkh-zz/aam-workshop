#!/bin/bash

printf '\nInitializing Conjur Secrets'
printf '\nSetting Ansible Secret: '
conjur variable values add apps/secrets/cd-variables/ansible_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
printf 'Setting Electric Secret: '
conjur variable values add apps/secrets/cd-variables/electric_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
printf 'Setting OpenShift Secret: '
conjur variable values add apps/secrets/cd-variables/openshift_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
printf 'Setting Docker Secret: '
conjur variable values add apps/secrets/cd-variables/docker_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
printf 'Setting AWS Secret: '
conjur variable values add apps/secrets/cd-variables/aws_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
printf 'Setting Azure Secret: '
conjur variable values add apps/secrets/cd-variables/azure_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
printf 'Setting Kubernetes Secret: '
conjur variable values add apps/secrets/cd-variables/kubernetes_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
printf 'Setting Puppet Secret: '
conjur variable values add apps/secrets/ci-variables/puppet_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
printf 'Setting Chef Secret: '
conjur variable values add apps/secrets/ci-variables/chef_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
printf 'Setting Jenkins Secret: '
conjur variable values add apps/secrets/ci-variables/jenkins_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
