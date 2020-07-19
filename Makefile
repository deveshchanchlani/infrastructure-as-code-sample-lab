
run: stop start exec

start:
	docker run -it -d --env AWS_PROFILE="kh-labs" --env TF_PLUGIN_CACHE_DIR="/plugin-cache" -v /var/run/docker.sock:/var/run/docker.sock -v $$(pwd):/work -v $$PWD/creds:/root/.aws -v terraform-plugin-cache:/plugin-cache -w /work --name pawst bryandollery/terraform-packer-aws-alpine

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

up:
	time terraform apply -auto-approve -var-file=terraform.tfvars

down:
	time terraform destroy -auto-approve 

test:
	ssh -i ssh/id_rsa ubuntu@$$(terraform output -json | jq '."prod-databases".value[0]' | xargs)
init:
	rm -rf .terraform ssh
	mkdir ssh
	time terraform init
	ssh-keygen -t rsa -f ./ssh/id_rsa -q -N ""	
