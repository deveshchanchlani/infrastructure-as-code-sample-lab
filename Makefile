
run: stop start exec

up: fmt plan apply

start:
	docker run -it -d --env TF_NAMESPACE=$$TF_NAMESPACE --env AWS_PROFILE="kh-labs" --env TF_PLUGIN_CACHE_DIR="/plugin-cache" -v /var/run/docker.sock:/var/run/docker.sock -v $$(pwd):/work -v $$PWD/creds:/root/.aws -v terraform-plugin-cache:/plugin-cache -w /work --name pawst bryandollery/terraform-packer-aws-alpine

exec:
	docker exec -it pawst bash || true

stop:
	docker rm -f pawst 2> /dev/null || true

fmt:
	time terraform fmt -recursive

plan:
	time terraform plan -out plan.out -var-file=terraform.tfvars

apply:
	time terraform apply plan.out 

down:
	time terraform destroy -auto-approve 

test:
	ssh -i ssh/id_rsa ubuntu@$$(terraform output -json | jq '.bastion_ip.value' | xargs) rm -f /home/ubuntu/id_rsa
	scp -i ssh/id_rsa ssh/id_rsa ubuntu@$$(terraform output -json | jq '.bastion_ip.value' | xargs):~
	ssh -i ssh/id_rsa ubuntu@$$(terraform output -json | jq '.bastion_ip.value' | xargs) chmod 400 /home/ubuntu/id_rsa
	ssh -i ssh/id_rsa ubuntu@$$(terraform output -json | jq '.bastion_ip.value' | xargs)
init:
	rm -rf .terraform ssh
	mkdir ssh
	time terraform init -backend-config="bucket=devops-bootcamp-remote-state-$$TF_NAMESPACE" -backend-config="key=$$TF_NAMESPACE/labs/terraform.tfstate" -backend-config="dynamodb_table=devops-bootcamp-locks-$$TF_NAMESPACE"
	ssh-keygen -t rsa -f ./ssh/id_rsa -q -N ""
