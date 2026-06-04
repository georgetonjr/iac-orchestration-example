# IaC Orchestration Example — Digger + AWS

Demo de orquestração de infraestrutura com Digger via GitHub Actions e AWS.

## Stack

- **Digger** — orquestração de plan/apply via PR
- **Terraform** — IaC
- **AWS S3** — remote state
- **AWS DynamoDB** — state lock
- **GitHub Actions** — CI/CD
- **AWS OIDC** — autenticação sem chave de acesso

## Fluxo da demo

1. Abre um PR com mudança no `main.tf`
2. Digger comenta automaticamente com o `terraform plan`
3. Comenta `digger apply` no PR
4. GitHub Actions autentica na AWS via OIDC e roda o `terraform apply`
5. Recurso é provisionado na AWS

## Setup inicial

### 1. Bootstrap do state (roda uma vez localmente)

```bash
# Configure suas credenciais AWS localmente
aws configure

# Rode o bootstrap para criar o bucket S3 e tabela DynamoDB
cd bootstrap
terraform init
terraform apply

# Após criar os recursos, remova o bootstrap.tf da raiz
```

### 2. Configure o OIDC na AWS

Crie uma IAM Role que o GitHub Actions pode assumir via OIDC:

```bash
# Substitua com seu usuário/repo do GitHub
GITHUB_REPO="georgetonjr/iac-orchestration-example"

# Crie o Identity Provider OIDC na AWS
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# Crie a IAM Role (salve o ARN retornado)
aws iam create-role \
  --role-name GitHubActions-Digger \
  --assume-role-policy-document "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [{
      \"Effect\": \"Allow\",
      \"Principal\": {\"Federated\": \"arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):oidc-provider/token.actions.githubusercontent.com\"},
      \"Action\": \"sts:AssumeRoleWithWebIdentity\",
      \"Condition\": {
        \"StringLike\": {
          \"token.actions.githubusercontent.com:sub\": \"repo:${GITHUB_REPO}:*\"
        }
      }
    }]
  }"

# Anexe as permissões necessárias
aws iam attach-role-policy \
  --role-name GitHubActions-Digger \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
```

### 3. Configure o secret no GitHub

No repositório GitHub, vá em **Settings → Secrets → Actions** e adicione:

| Secret | Valor |
|--------|-------|
| `AWS_ROLE_ARN` | ARN da role criada acima (ex: `arn:aws:iam::123456789:role/GitHubActions-Digger`) |

### 4. Teste

```bash
git checkout -b feat/teste-digger
# faça qualquer alteração no main.tf (ex: mude var.env default para "staging")
git add . && git commit -m "test: altera env para staging"
git push origin feat/teste-digger
# abra o PR no GitHub e observe o Digger comentar o plan
```
