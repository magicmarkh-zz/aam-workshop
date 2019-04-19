#sample script to retrieve credential from conjur
main(){
  printf '\n-----'
  printf '\nThis Script will pull a secret via REST.'
  secret_pull 
  printf '\n-----\n'
}

secret_pull(){
  local master_name=conjur-master
  local company_name=workshop
  local api=$(cat ~/.netrc | awk '/password/ {print $2}')
  local host_name=$(cat ~/.netrc | awk '/login/ {print $2}')
  local secret_name="secrets/aws-secret"
  local auth=$(curl -s -k -H "Content-Type: text/plain" -X POST -d "$api" http://$master_name/authn/$company_name/$host_name/authenticate)
  local auth_token=$(echo -n $auth | base64 | tr -d '\r\n')
  local secret_retrieve=$(curl -s -k -X GET -H "Authorization: Token token=\"$auth_token\"" http://$master_name/secrets/$company_name/variable/$secret_name)
  printf "\n"
  printf "\nSecret is: $secret_retrieve" 
}

main