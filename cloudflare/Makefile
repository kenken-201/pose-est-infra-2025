.PHONY: init plan apply fmt validate lint verify-auth

# .env ファイルが存在すれば読み込み、変数をエクスポートする
# これにより TF_VAR_CLOUDFLARE_ZONE_ID などを Terraform コマンドに渡せます
-include .env
export

TERRAFORM_DIR := terraform
SCRIPTS_DIR := scripts

verify-auth:
	./$(SCRIPTS_DIR)/verify-auth.sh

init:
	cd $(TERRAFORM_DIR) && terraform init

plan:
	cd $(TERRAFORM_DIR) && terraform plan

apply:
	cd $(TERRAFORM_DIR) && terraform apply

fmt:
	cd $(TERRAFORM_DIR) && terraform fmt -recursive

validate:
	cd $(TERRAFORM_DIR) && terraform validate

lint:
	cd $(TERRAFORM_DIR) && tflint --init && tflint
