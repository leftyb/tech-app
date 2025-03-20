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
- Docker running on the local machine.

#### Execution

Run this at `./` directory inside the repository: `devbox shell --env ENV=dev`

Steps that are done automatically:

- Will install in an isolated shells environment all necessary packages (check `devbox.json`).
- Create/Prepare Kind cluster
- Run the necessary manifest files for the application.
- Run the necessary tests

#### Clean up

Run this at `./` directory inside the repository: `devbox run clean-all --env ENV=dev`

Steps that are done automatically:

- Deletes `Kind` cluster.

### Production (prod)

 This mode runs entirely on `AWS EKS` cluster.
 It uses `terraform` to create all necessary resources.

#### Prerequisites

In order to properly exectute the tech challenge following are requested on the local environment:

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
    ```
    # aws_credentials.sh
    export AWS_ACCESS_KEY_ID="YOUR_AWS_ACCESS_KEY"
    export AWS_SECRET_ACCESS_KEY="YOUR_AWS_SECRET_KEY"
    export AWS_DEFAULT_REGION="AWS_REGION_TO_CREATE_RESOURCES"
    ```

#### Execution

Run this at `root` directory inside the repository: `devbox shell --env ENV=prod`

- `-auto-approve` Is disabled, you can enable it using `TF_AUTO_APPROVE=true` e.g. `devbox shell --env ENV=prod --env TF_AUTO_APPROVE=true`

Steps that are done automatically:

- Will install in an isolated shells environment all necessary packages (check `devbox.json`).
- Create all `AWS` resources with `terraform`
- Apply the necessary manifests for `Karpenter` 
- Apply necessary manifest files for the application.
- Run the necessary tests.

#### Clean up

Run this at `root` directory inside the repository: `devbox run clean-all --env ENV=prod`

- `-auto-approve` Is disabled, you can enable it using `TF_AUTO_APPROVE=true` e.g. `devbox run clean-all --env ENV=prod --env TF_AUTO_APPROVE=true`

Steps that are done automatically:

- Deletes `AWS` cluster resources.
  - Including `s3bucket` where statefile is stored.

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

terraform state rm module.state-infra.aws_s3_bucket.tfstate_bucket

#### Destroy all infrastucture manually

Some resources might not get deleted due to dependencies when run the `clear-up` script.

***INFO***
PLease make sure that you delete all the remaining resources manually if needed.

- Go to the `infra` directory
  - Run `terraform plan` at both `app-infra` & `state-infra` directories.
    - You can see which resources have not been deleted.
  - Try to apply again, and if not success delete them manually from the console.
  - Check it the S3 bucket `tech-app-state-bucket` is deleted as well.


#### Details on execution

`Devbox` is creating  an isolated shells environment. All installed packages will be installed locally at the repository directory (`.devbox` dir).

