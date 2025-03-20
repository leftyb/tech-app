# Demo app for tech challenge

On this repository we developed the solution requested for the tech challenge.
Requirements:

- Not displayed here as this is a public repo.
- ...

## Modes

Two modes of execution are provided `dev` and `prod`

### Development (dev)

    This mode runs entirely on the local machine using `Kind` cluster.

#### Prerequisites  

- [Devbox](https://www.jetify.com/docs/devbox/cli_reference/devbox_shell/).
  - Install information can be found [here](https://github.com/jetify-com/devbox?tab=readme-ov-file#installing-devbox)
- Docker running on the local machine.

#### Execution

Run this at `./` directory inside the repository: `devbox run --env ENV=dev setup-all -q`

- `--env ENV=dev`: will be executed on Kind cluster
- `-q`: suppress devbox logs

Steps that are done automatically:

- Will install in an isolated shells environment all necessary packages (check `devbox.json`).
- Create/Prepare Kind cluster
- Run the necessary manifest files for the application.
- Run the necessary tests

#### Run tests

- Run just the tests after `setup` with `devbox run --env ENV=dev run-tests`

#### Clean up

Run this at `./` directory inside the repository: `devbox run --env ENV=dev clean-all -q`

Steps that are done automatically:

- Deletes `Kind` cluster.

### Production (prod)

 This mode runs entirely on `AWS EKS` cluster.
 It uses `terraform` to create all necessary resources.

#### Prerequisites

In order to properly exectute the tech challenge following are requested on the local environment:

- [Devbox](https://www.jetify.com/docs/devbox/cli_reference/devbox_shell/).
  - Install information can be found [here](https://github.com/jetify-com/devbox?tab=readme-ov-file#installing-devbox)
- AWS valid credentials (as AWS has been choosen the provider to be used).
  - Make sure that `AWS Role` used has necessary permitions for the AWS resources to be created (most at least to be able to `create`, `list`, `delete` ):
    - VPC (plus dependencies: subnets, routing tables, etc).
    - EKS ( and all dependencies)
    - NLB
    - Fargate for EKS
    - Karpenter
    - S3
    - ...
    - Check the `infra` dir for all terraform code used.

#### configuration

- create a `aws_credentials.sh` file at the `./` of the repository:

  sh```
    # aws_credentials.sh
    export AWS_ACCESS_KEY_ID="YOUR_AWS_ACCESS_KEY"
    export AWS_SECRET_ACCESS_KEY="YOUR_AWS_SECRET_KEY"
    export AWS_DEFAULT_REGION="AWS_REGION_TO_CREATE_RESOURCES"
  ```

#### Execution

Run this at `./` directory inside the repository: `devbox run --env ENV=prod setup-all -q`

- `--env ENV=prod`: will be executed on AWS EKS cluster (will be created as well with Terraform).
- `-q`: suppress devbox logs

- `-auto-approve` Is disabled, you can enable it using `TF_AUTO_APPROVE=true` e.g. `devbox run --env ENV=prod --env TF_AUTO_APPROVE=true setup-all -q`
  - WARNING: This will apply all terraform resources withought manual input.

Steps that are done automatically:

- Will install in an isolated shells environment all necessary packages (check `devbox.json`).
- Create all `AWS` resources with `terraform`
- Apply the necessary manifests for `Karpenter` 
- Apply necessary manifest files for the application.
- Run the necessary tests.

#### Run tests

- Run just the tests after `setup` with `devbox run --env ENV=prod run-tests`

#### Clean up

Run this at `./` directory inside the repository: `devbox run --env ENV=prod clean-all -q`

- `-auto-approve` Is disabled, you can enable it using `TF_AUTO_APPROVE=true` e.g. `devbox run --env ENV=prod --env TF_AUTO_APPROVE=true clean-all -q`

Steps that are done automatically:

- Deletes `AWS` cluster resources.
  - Including `s3bucket` where statefile is stored.

## GitHub Workflows

A workflow is as well available just for the `prod` mode.

- Create: Uses same `devbox` script to create the `EKS` cluster and apply the `app` manifests and run the tests.
  - The bad thing with this is that `devbox` setup takes too long. Up to `30 minutes`
- Destroy: Uses same `devbox` scripts to destroy the created `AWS` resources.
  - Please refair to [ Manually Destroy Section](#destroy-all-infrastructure-manually) for some additional information.
- argocd: Deploys `argocd` at the created cluster, and applies an argocd application that is linked to the `app-manifests` dir in same repo, where the demo app manifests are located. 

## Addition information

Additional information regarding other details.

### Docker Image

All related files exist at the `app` directory.

#### Docker build image

`docker build -t your-dockerhub-username/your-app-name:tag .`

#### Docker push image

`docker push your-dockerhub-username/your-app-name:tag`

***INFO***
Make sure you update the `deployment` at `app-manifests/all-manifests.yaml`

#### Destroy all infrastucture manually

Some resources might not get deleted due to dependencies when run the `clear-up` script.

***INFO***
PLease make sure that you delete all the remaining resources manually if needed.

- Go to the `infra` directory
  - Run `terraform plan` at both `app-infra` & `state-infra` directories.
    - You can see which resources have not been deleted.
  - Try to apply again, and if not success delete them manually from the console.
  - Check it the S3 bucket `tech-app-state-bucket` is deleted as well.
  - Check that all `ec2` instances are destroyed. Due to that are automatically created from `Karpenter` and not managed from `terraform`
  - Check that all `VPC` resources are deleted.

#### Details on execution

`Devbox` is creating  an isolated shells environment. All installed packages will be installed locally at the repository directory (`.devbox` dir).