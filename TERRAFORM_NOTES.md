# 📘 Terraform Learning Notes — From Scratch to Pro

A structured notebook built from everything we've touched (and the deeper "why" behind each piece). Treat this as your personal cheat sheet — add to it as you go.

---

## 📑 Table of Contents

1. [What is Terraform?](#1-what-is-terraform)
2. [Core Concepts](#2-core-concepts)
3. [Terraform Workflow](#3-terraform-workflow)
4. [Project Structure](#4-project-structure)
5. [HCL Syntax Essentials](#5-hcl-syntax-essentials)
6. [State Management](#6-state-management)
7. [Backends](#7-backends)
8. [Modules](#8-modules)
9. [Variables, Locals & Outputs](#9-variables-locals--outputs)
10. [Providers](#10-providers)
11. [Resources vs Data Sources](#11-resources-vs-data-sources)
12. [Meta-Arguments](#12-meta-arguments)
13. [Expressions & Functions](#13-expressions--functions)
14. [CLI Commands Cheat Sheet](#14-cli-commands-cheat-sheet)
15. [Troubleshooting Patterns](#15-troubleshooting-patterns)
16. [Best Practices](#16-best-practices)
17. [Common Mistakes](#17-common-mistakes)
18. [Advanced Topics (Future Learning)](#18-advanced-topics-future-learning)

---

## 1. What is Terraform?

**Terraform** is an **Infrastructure as Code (IaC)** tool by HashiCorp that lets you **define, provision, and manage** cloud infrastructure using declarative configuration files.

### Why Terraform?
| Problem | Terraform Solves |
|---|---|
| Manual clicking in AWS Console | Define everything as code |
| "Works on my machine" infra | Reproducible across environments |
| Config drift between dev/prod | Same code, different variables |
| Hard to review infra changes | Pull requests + `terraform plan` |
| Lost knowledge when engineer leaves | Code is self-documenting |

### Declarative vs Imperative
```hcl
# ✅ Declarative (Terraform): Describe DESIRED state
resource "aws_s3_bucket" "data" {
  bucket = "my-data-bucket"
}
# Terraform figures out HOW to get there
```
```bash
# ❌ Imperative (shell): Describe STEPS
aws s3api create-bucket --bucket my-data-bucket
# You must handle "does it exist?", "what if it fails mid-way?", etc.
```

---

## 2. Core Concepts

| Concept | Meaning |
|---|---|
| **Provider** | A plugin that talks to a specific API (AWS, Azure, GitHub, etc.) |
| **Resource** | A single piece of infrastructure (an EC2 instance, S3 bucket, VPC...) |
| **Data Source** | A read-only lookup of existing infrastructure |
| **Module** | A reusable, parameterized bundle of resources |
| **State** | Terraform's memory — a JSON file mapping config → real-world resources |
| **Backend** | Where state is stored (local file, S3, Terraform Cloud...) |
| **Plan** | Preview of what will change on the next apply |
| **Apply** | Actually make the changes |

---

## 3. Terraform Workflow

```
┌──────────────────────────────────────────────────────────────┐
│                    THE TERRAFORM LOOP                        │
└──────────────────────────────────────────────────────────────┘

   write .tf files
        │
        ▼
  terraform init    ← downloads providers, configures backend
        │
        ▼
  terraform fmt     ← auto-formats code
        │
        ▼
  terraform validate ← checks syntax
        │
        ▼
  terraform plan    ← preview changes (SAFE, no modifications)
        │
        ▼
  terraform apply   ← executes the changes (writes to state)
        │
        ▼
   use/verify infra
        │
        ▼
  terraform destroy ← tear it all down (cleanup)
```

> **Golden Rule:** Always `plan` before `apply`. Always.

---

## 4. Project Structure

### Minimum (single environment)
```
project/
├── main.tf          # resources
├── variables.tf     # inputs
├── outputs.tf       # exports
├── providers.tf     # provider config
└── terraform.tfvars # variable values
```

### Scalable (multi-env + modules) — ✅ what we're using
```
infra/
├── bootstrap/              # one-time setup (S3 + DynamoDB for state)
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── modules/                # reusable building blocks
│   ├── vpc/
│   ├── security-groups/
│   ├── rds/
│   ├── ecr/
│   └── ssm-parameters/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── environments/           # one folder per environment
    ├── dev/
    │   ├── backend.tf      # S3 backend config
    │   ├── providers.tf
    │   ├── main.tf         # calls modules
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── terraform.tfvars
    │
    ├── staging/
    └── prod/
```

**Why this structure?**
- Separate **state file per environment** → prevents accidental prod changes
- **Modules** keep code DRY
- Easy for CI/CD to target one environment at a time

---

## 5. HCL Syntax Essentials

HCL = **HashiCorp Configuration Language**

### Resource Block
```hcl
resource "<TYPE>" "<LOCAL_NAME>" {
  argument1 = "value1"
  argument2 = 123
  
  nested_block {
    key = "value"
  }
}
```

Example:
```hcl
resource "aws_vpc" "main" {           # TYPE = aws_vpc,  NAME = main
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "my-vpc"
  }
}
```

### Reference syntax
```
<TYPE>.<NAME>.<ATTRIBUTE>
```
```hcl
aws_vpc.main.id              # resource attribute
var.region                   # variable
module.vpc.vpc_id            # module output
data.aws_ami.ubuntu.id       # data source
local.name_prefix            # local value
```

### String Interpolation
```hcl
name = "${var.project}-${var.env}-vpc"
# Modern style (no $ needed in simple refs):
name = "my-vpc"
tags = {
  Name = "${local.name_prefix}-subnet"
}
```

---

## 6. State Management

### What is State?
A **JSON file** that maps your `.tf` configuration → actual resources in the cloud.

```json
// Simplified terraform.tfstate
{
  "resources": [
    {
      "type": "aws_vpc",
      "name": "main",
      "instances": [{
        "attributes": {
          "id": "vpc-0abc123",
          "cidr_block": "10.0.0.0/16"
        }
      }]
    }
  ]
}
```

### Why State is Critical
- Terraform needs it to know **what exists** so it can decide **what to change**
- Without state, Terraform would try to recreate everything every time
- State includes **secrets in plaintext** → NEVER commit to Git

### State Problems & Solutions
| Problem | Solution |
|---|---|
| Lost local state → infra is "orphaned" | **Remote state** (S3) |
| Two engineers run `apply` at the same time | **State locking** (DynamoDB) |
| State contains secrets | **Encrypt** backend (S3 SSE) |
| Accidental deletion | **Versioning** (S3 versioning) |

### What we set up (bootstrap)
```hcl
# S3 bucket = shared state
# DynamoDB = lock (one person at a time)
# Encryption + Versioning = safety
```

---

## 7. Backends

A **backend** defines WHERE state is stored.

### Local backend (default)
```hcl
# No backend block = local state in terraform.tfstate
```

### S3 backend (what we're using)
```hcl
terraform {
  backend "s3" {
    bucket         = "my-tf-state-bucket"
    key            = "dev/terraform.tfstate"   # path inside bucket
    region         = "us-east-1"
    dynamodb_table = "tf-lock"
    encrypt        = true
  }
}
```

### Backend Rules
1. Backend config can't use variables → values must be **literal** or passed via `-backend-config=...`
2. Changing backend → run `terraform init -migrate-state`
3. Each environment should have a different `key` in the same bucket

---

## 8. Modules

A **module** is a reusable, parameterized bundle of Terraform code.

### Types
| Type | Where it lives |
|---|---|
| **Root module** | Your working directory (what Terraform runs) |
| **Child module** | Called by root via `module ""` block |
| **Local module** | `source = "../../modules/vpc"` |
| **Registry module** | `source = "terraform-aws-modules/vpc/aws"` |
| **Git module** | `source = "git::https://github.com/..."` |

### Anatomy of a Module
```
modules/vpc/
├── main.tf       # what it creates
├── variables.tf  # inputs (what callers pass in)
└── outputs.tf    # exports (what callers can read back)
```

### Calling a Module
```hcl
module "vpc" {
  source = "../../modules/vpc"

  # Inputs → these must match the module's variables.tf
  name_prefix = "myapp-dev"
  vpc_cidr    = "10.0.0.0/16"
}

# Use outputs
subnet_ids = module.vpc.private_subnet_ids
```

### Why Modules?
- **DRY** — one definition, use it in dev/staging/prod
- **Encapsulation** — hide complexity behind a clean interface
- **Versioning** — pin module versions for stability
- **Testing** — test a module once, trust it everywhere

---

## 9. Variables, Locals & Outputs

### Variables (Inputs)
```hcl
# variables.tf
variable "aws_region" {
  description = "Which region to deploy to"
  type        = string
  default     = "us-east-1"
  
  validation {
    condition     = contains(["us-east-1", "eu-west-1"], var.aws_region)
    error_message = "Must be us-east-1 or eu-west-1."
  }
}
```

### Variable Types
```hcl
variable "name"     { type = string }
variable "count"    { type = number }
variable "enabled"  { type = bool }
variable "tags"     { type = map(string) }
variable "subnets"  { type = list(string) }
variable "settings" { 
  type = object({
    size = string
    tags = map(string)
  })
}
```

### Ways to Set Variable Values (precedence: high → low)
1. `-var "region=us-west-2"` on CLI
2. `-var-file="prod.tfvars"`
3. `terraform.tfvars` (auto-loaded)
4. `*.auto.tfvars` (auto-loaded)
5. `TF_VAR_region=us-west-2` environment variable
6. Default value in variable block
7. (Prompt the user)

### Locals (Computed Values)
```hcl
locals {
  name_prefix = "${var.project}-${var.env}"
  
  common_tags = {
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
  }
}

# Use with: local.name_prefix
```

**When to use locals vs variables?**
- `variable` = user supplies it (external input)
- `local` = internal computed value (DRY within one module)

### Outputs (Exports)
```hcl
# outputs.tf
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "db_password" {
  value     = random_password.db.result
  sensitive = true   # hides from CLI output
}
```

**Why outputs matter:**
- Expose module internals to the caller
- Share values across environments
- Can be queried: `terraform output vpc_id`

---

## 10. Providers

A **provider** is a plugin that talks to an API (AWS, Azure, GCP, GitHub, Datadog, ~3000+ available).

### Declaring Required Providers
```hcl
terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"    # 5.30 to <6.0
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
```

### Version Constraints
```
= 5.30.0     exact
!= 5.30.0    not this
~> 5.30      >= 5.30, < 6.0  (recommended)
>= 5.0, < 6.0  range
```

### Configuring a Provider
```hcl
provider "aws" {
  region  = "us-east-1"
  profile = "my-profile"   # from ~/.aws/credentials
  
  default_tags {
    tags = {
      ManagedBy = "terraform"
    }
  }
}
```

### Multiple Provider Instances (alias)
```hcl
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

resource "aws_s3_bucket" "west_bucket" {
  provider = aws.west
  bucket   = "west-bucket"
}
```

---

## 11. Resources vs Data Sources

### Resource = Create & Manage
```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
# Terraform OWNS this → creates, updates, destroys
```

### Data Source = Read Existing
```hcl
data "aws_availability_zones" "available" {
  state = "available"
}

# Use it:
availability_zones = data.aws_availability_zones.available.names
# Terraform does NOT manage this → read-only lookup
```

Common data sources:
```hcl
data "aws_caller_identity" "current" {}  # → current account ID
data "aws_region" "current" {}            # → current region
data "aws_ami" "ubuntu" { ... }           # → latest Ubuntu AMI
```

---

## 12. Meta-Arguments

Special arguments that work on **any** resource.

### `count` — create N copies
```hcl
resource "aws_subnet" "public" {
  count      = 2
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.${count.index}.0/24"
}
# Access: aws_subnet.public[0], aws_subnet.public[1]
```

### `for_each` — create one per map/set item (more flexible)
```hcl
resource "aws_subnet" "public" {
  for_each = {
    az1 = "10.0.1.0/24"
    az2 = "10.0.2.0/24"
  }
  cidr_block = each.value
  vpc_id     = aws_vpc.main.id
}
# Access: aws_subnet.public["az1"]
```

### `depends_on` — explicit dependency
```hcl
resource "aws_nat_gateway" "main" {
  # ...
  depends_on = [aws_internet_gateway.main]
}
```

### `lifecycle` — control behavior
```hcl
resource "aws_instance" "web" {
  # ...
  lifecycle {
    prevent_destroy       = true    # safety
    create_before_destroy = true    # avoid downtime
    ignore_changes        = [tags]  # don't rebuild on tag changes
  }
}
```

### `provider` — use a non-default provider
```hcl
resource "aws_s3_bucket" "backup" {
  provider = aws.west
  bucket   = "backup-bucket"
}
```

---

## 13. Expressions & Functions

### Conditionals
```hcl
multi_az = var.environment == "prod" ? true : false

# Create resource conditionally
resource "aws_nat_gateway" "main" {
  count = var.enable_nat ? 1 : 0
}
```

### Common Functions
```hcl
# String
upper("hello")              # → "HELLO"
format("%s-%s", "a", "b")   # → "a-b"
join(",", ["a", "b"])       # → "a,b"
split(",", "a,b,c")         # → ["a","b","c"]

# Collection
length(["a","b","c"])        # → 3
slice(list, 0, 2)            # → first 2 elements
contains(list, "value")      # → true/false
merge({a=1}, {b=2})          # → {a=1, b=2}

# Encoding
jsonencode({key = "value"})  # → "{\"key\":\"value\"}"
jsondecode(json_string)      # → object

# File
file("path/to/file.txt")

# Date
timestamp()
formatdate("YYYY-MM-DD", timestamp())
```

### Loops with `for`
```hcl
# Transform a list
names = [for s in var.subnets : s.name]

# Filter + transform
public = [for s in var.subnets : s.id if s.public == true]

# Create a map
tags = {for k, v in var.tags : k => upper(v)}
```

### Dynamic Blocks
```hcl
resource "aws_security_group" "web" {
  dynamic "ingress" {
    for_each = var.ingress_ports
    content {
      from_port = ingress.value
      to_port   = ingress.value
      protocol  = "tcp"
    }
  }
}
```

---

## 14. CLI Commands Cheat Sheet

### Setup
```bash
terraform init                      # download providers, set up backend
terraform init -upgrade             # upgrade providers
terraform init -migrate-state       # move state to new backend
terraform init -reconfigure         # change backend without migrating
```

### Daily workflow
```bash
terraform fmt -recursive            # format all .tf files
terraform validate                  # syntax check
terraform plan                      # preview changes
terraform plan -out=tfplan          # save plan to file
terraform apply                     # apply changes
terraform apply tfplan              # apply saved plan (no re-prompt)
terraform apply -auto-approve       # skip confirmation (CI/CD)
terraform destroy                   # destroy everything
terraform destroy -target=aws_vpc.main  # destroy specific resource
```

### Inspection
```bash
terraform show                      # show current state
terraform state list                # list all managed resources
terraform state show aws_vpc.main   # show one resource's state
terraform output                    # show all outputs
terraform output vpc_id             # show one output
terraform output -raw vpc_id        # unquoted (for scripting)
terraform providers                 # list providers in use
terraform version                   # terraform + provider versions
```

### State manipulation (⚠️ advanced)
```bash
terraform state mv old new          # rename a resource in state
terraform state rm aws_vpc.main     # remove from state (don't delete)
terraform import aws_vpc.main vpc-0abc  # bring existing resource under TF control
terraform refresh                   # sync state with real infrastructure
```

### Workspaces (basic multi-env — we don't use this, we use folders)
```bash
terraform workspace list
terraform workspace new staging
terraform workspace select prod
```

---

## 15. Troubleshooting Patterns

### Problem → Fix Table (from our actual sessions!)

| Error Message | Root Cause | Fix |
|---|---|---|
| `Backend configuration changed` | Added/changed providers block | `terraform init -migrate-state` |
| `This object has no attribute "xxx"` | Module output not defined | Add `output` block in module's `outputs.tf` |
| `Cannot find version X.Y for postgres` | Engine version deprecated in region | Query with `aws rds describe-db-engine-versions` and use a current one |
| `Error acquiring state lock` | Previous `apply` crashed OR someone else is applying | `terraform force-unlock LOCK_ID` (only if sure!) |
| `Error: Resource already exists` | Resource exists in cloud but not in state | `terraform import` to adopt it |
| `exec format error` in ECS logs | Image built for wrong CPU arch (ARM on x86) | `docker build --platform linux/amd64` |

### Debugging commands
```bash
# Verbose logging
export TF_LOG=DEBUG
terraform plan

# Just see provider API calls
export TF_LOG=TRACE
export TF_LOG_PATH=./terraform.log
```

---

## 16. Best Practices

### ✅ DO
- **Always `terraform plan` before `apply`**
- Use **remote state** with locking from day 1
- Enable **S3 versioning** on your state bucket
- Keep **modules small & focused** (one responsibility)
- Pin **provider versions** (`~> 5.30`)
- Pin **Terraform version** (`required_version = ">= 1.6"`)
- Use **tags** on every resource (`default_tags` block)
- One **state file per environment**
- **Format code**: `terraform fmt -recursive`
- Use **descriptive variable descriptions** (self-docs!)
- Commit `.terraform.lock.hcl` → locks provider versions

### ❌ DON'T
- ❌ Commit `terraform.tfstate` to Git
- ❌ Commit `.tfvars` files with secrets
- ❌ Store secrets in `.tf` files
- ❌ Edit state file by hand (unless desperate)
- ❌ Use `terraform apply -auto-approve` locally (CI only)
- ❌ Mix prod & dev in the same state
- ❌ Make modules too generic (over-engineering)
- ❌ Use `count` when `for_each` is clearer (and vice versa)

### `.gitignore` must-haves
```
*.tfstate
*.tfstate.*
.terraform/
*.tfvars
!*.tfvars.example
crash.log
override.tf
override.tf.json
*_override.tf
```

---

## 17. Common Mistakes

### Mistake 1: Hardcoding Values
```hcl
# ❌ Bad
resource "aws_instance" "web" {
  ami           = "ami-0abc123"
  instance_type = "t2.micro"
}

# ✅ Good
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
}
```

### Mistake 2: Not Using Modules
```hcl
# ❌ 500 lines of VPC code in main.tf
# ✅ One module call:
module "vpc" {
  source = "../../modules/vpc"
  # ...
}
```

### Mistake 3: Forgetting Outputs in Modules
```hcl
# Module creates aws_vpc.main but no outputs.tf → caller can't use it!
# Always expose what callers might need.
```

### Mistake 4: Using `count` with Unknown Values
```hcl
# ❌ Fails on first plan — count can't depend on unknown values
resource "aws_subnet" "a" {
  count = length(data.aws_vpc.x.cidr_block_associations)
}

# ✅ Use for_each with a known key set
```

### Mistake 5: Modifying State by Hand
```bash
# ❌ vim terraform.tfstate  → corruption risk
# ✅ Use terraform state mv/rm/import commands
```

---

## 18. Advanced Topics (Future Learning)

As you progress, explore these:

| Topic | What it is |
|---|---|
| **Terraform Workspaces** | Multiple states in one directory (we use folders instead — cleaner) |
| **Terragrunt** | DRY wrapper around Terraform for huge projects |
| **Terraform Cloud / Enterprise** | HashiCorp's SaaS for state + runs + collab |
| **Sentinel / OPA** | Policy-as-code gates on Terraform plans |
| **Testing (Terratest, `terraform test`)** | Automated infra testing in Go |
| **Dynamic Providers** | Multi-account/region deployments |
| **CDK for Terraform** | Write Terraform in Python/TypeScript |
| **Moved blocks** | Refactor without destroying resources |
| **Import blocks (TF 1.5+)** | Declarative imports |
| **Checks (TF 1.5+)** | Continuous validation of live infra |

---

## 📎 Quick Reference Card

```
┌──────────────────────────────────────────────────────┐
│  TERRAFORM QUICK REFERENCE                           │
├──────────────────────────────────────────────────────┤
│  Init     →  terraform init                          │
│  Preview  →  terraform plan                          │
│  Deploy   →  terraform apply                         │
│  Cleanup  →  terraform destroy                       │
│  Format   →  terraform fmt -recursive                │
│  Validate →  terraform validate                      │
│  Output   →  terraform output <name>                 │
├──────────────────────────────────────────────────────┤
│  Reference syntax:                                   │
│    Resource  → aws_vpc.main.id                       │
│    Variable  → var.region                            │
│    Local     → local.name_prefix                     │
│    Output    → module.vpc.vpc_id                     │
│    Data      → data.aws_ami.ubuntu.id                │
├──────────────────────────────────────────────────────┤
│  File structure:                                     │
│    main.tf       → resources                         │
│    variables.tf  → inputs                            │
│    outputs.tf    → exports                           │
│    providers.tf  → provider config                   │
│    backend.tf    → state storage                     │
│    *.tfvars      → variable values                   │
├──────────────────────────────────────────────────────┤
│  State files = SECRETS → never commit to git!        │
│  Always `plan` before `apply`                        │
│  Use remote state (S3 + DynamoDB) always             │
└──────────────────────────────────────────────────────┘
```