#!/bin/bash

printf '\nInitializing Conjur Secrets'
printf '\nSetting AWS Secret: '
conjur variable values add secrets/aws-secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
printf 'Setting Azure Secret: '
conjur variable values add secrets/azure-secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
printf 'Setting GCP Secret: '
conjur variable values add secrets/gcp-secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)