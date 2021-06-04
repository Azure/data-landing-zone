# Introduction

Just as a short recap, the Harmonized Mesh architecture was designed with the following core principles in mind:

1. Self Service Enablement: Enable project teams to work on their own in order to allow agile development methods.
2. Governance: Enforce guardrails on the whole Azure platform, in order to ensure that project teams are only allowed to see, change and execute what they are supposed to.
3. Streamlined Deployments: Ensure that common blueprints are available and can be used across the organization to scale quickly and to enable teams, which are not as experienced with some of core designs and artifacts.
4. ...

The deployment process and Data Ops working model is an essential part and enabler for some of these core principles. In order to fulfill these concepts, the Azure Harmonized mesh proposes the following design guidelines, which will be covered in more detail in the following sections:

1. Use of Infrastructure as Code (IaC).
2. Deployment templates covering the core use cases within the company
3. Deployment process that includes a forking and branching strategy
4. Central repository and deployment of data hub
5. ...

## Deployment principles

## Infrastructure As Code (IaC)

Every layer of the mesh (data hub, data nodes, data domains or data products) should be defined through a declarative language such as ARM or Terraform, should be checked into a repository and deployed through CI/CD pipelines. This allows teams to keep track and version changes to the infrastructure and configuration of Azure scope and ultimately allows an agile self-service automation of different levels of the architecture. This concept allows to always have a clear representation of the state inside a specific scope in Azure in a Git repository.

## Deployment templates

In order to scale quickly within an organization and simplify the deployment process for teams, which are not as familiar with the concept of IaC, the Data Platform Team has the responsibility to provide and maintain deployment templates. These templates are used as a baseline for new artifacts within the Data Mesh and need to be maintained over time, in order to constantly represent best practices and common standards within the company.

The Data Platform Team has to provide the following core templates amongst others:

|Git Repo|Content|Required Y/N|Deployment model|
|-|-|-|-|
|[Data Hub Template](https://github.com/Azure/data-hub)| Central data management services as well as shared data services such as data catalog, SHIR etc. | Mandatory | One per Data Mesh |
|[Data Node Template](https://github.com/Azure/data-node)| Shared services for a data node like data storage and ingestion services as well as management services | Mandatory | One or many per Data Mesh |
| [Data Domain Template](https://github.com/Azure/data-domain) | Additional services required for a data domain | Optional | One or many per Data Node |
|[Data Product Template - Standard](https://github.com/Azure/data-product)| Additional services required for a data product | Optional | One or many per Data Node |
| [Data Product Template - Analytics](https://github.com/Azure/data-product-analytics) | Additional services required for a data product | Optional | One or many per Data Node|

These templates should not only contain ARM templates and the respective parameter files, but also CI/CD pipeline definitions for deploying the resources.

Because of new requirements and new services on Azure, these templates will evolve over time. Therefore the `main` branch of these repos should be secured to ensure that it is always error free and ready for consumption and deployment. A development subscription should be used to test changes to the configuration of the templates, before merging feature enhancements back into the `main` branch.

## Deployment process

The data mesh architecture consists of

- One data hub,
- One or more data nodes,
- One or more data domains in each data node,
- One or more data products in each data node.

Each of these assets can evolve independently over time, because of different requirements and lifecycle (e.g. one of the data nodes may requires RA-GRS storage accounts at some point). Therefore it is important to have an IaC representation of each of these assets in a Git repository, so that changes can be implemented based on requirements in the respective node, domain or product.

To not start from scratch for each asset, teams can leverage the templates provided by the Data Platform Ops team. In order to automate the deployment of a deployment template, it is recommended to implement a forking pattern.

For example, if a new data needs to be created, the responsible data node ops team can request a new node through a management tool like ServiceNow, Power Apps or other kinds of applications. After the request has been approved, the following process gets kicked off based on the provided parameters:

1. New subscription gets deployed for the new data node,
1. Master branch of the Data Node template gets forked into a new repository,
1. Service connection is created in the repository,
1. Parameters in forked repository gets updated based on the parameters and checked back into the repository,
1. By updating the parameters and checking in the updated code, the deployment pipeline gets kicked off and deploys the services
1. Data Node Ops team gets access to the repository.
1. Data Node Ops team can change or add ARM templates.

The workflow mentioned above needs to be orchestrated, which can be achieved through multiple sets of services on the Azure platform. Some of the steps should be handled through CI/CD pipelines, such as renaming parameters in parameter files, others can be executed in other workflow orchestration tools such as Logic Apps.

Azure policies put boundaries in place and ensure that changes performed by the data ops teams are compliant.

A forking pattern should be chosen, because it allows the different ops teams to follow the lifecycle of the original templates that the repos were forked from and that were used for the initial deployment. If new enhancements or changes are implemented in the template repositories, ops teams get the possibility to pull changes back to their repository, to leverage improvements and new features.

Best practices for Git repositories should be adopted in order to enforce the use of branches and pull requests. This includes:

- Securing the main branch
- Using branches for changes, updates and improvements
- Defining code owners, who have to approve pull requests, before merging them into the main branch
- Validating branches through automated testing
- Limiting the number of actions and persons in the team, who can trigger build and release pipelines
- etc.

Overall, this approach gives the different teams much greater flexibility, while also making sure that performed actions are compliant with the requirements of the company and, in addition, a lifecycle management is introduced, which allows to leverage new feature enhancements or optimizations added to the original templates.

## Central repository and deployment of data hub

The data hub is at the heart of the data mesh architecture and it constitutes of a single subscription. Since there is only a single instance of the hub, there is no need for templatizing the ARM templates or for creating a forking strategy. Therefore, the data hub should be managed centrally by the data platform team. A single repository should be used for the deployment and for updating and enhancing the data hub infrastructure and configuration. The data hub hosts central data management services as well as shared data services that should be used across the data mesh.

## Teams involved

|Name  |Role|Nbr of teams|
|-|-|-|
|Cloud Platform Ops| The Azure Cre Platform team in your organization| One for the whole Azure platform |
|Data Platform Ops|In charge of creating and maintaining ARM template repositories for the different levels of the data mesh. Also maintains the data hub and supports other ops teams in case of deployment issues or required enhancements.| One for the Data Mesh |
|Node Ops |In charge of deploying and maintaining a specific data node. Also, supports the deployment and enhancement of data domains and data products. | One team per Data Node |
|Domain Ops|In charge of Data Domain deployment and updates| One team per Data Domain |
|Data Product Team|In charge of Data Products deployment and updates| One team per Data Product |

## Step by Step Node Deployment Process

This deployment process is for the on-boarding of a new Data Node to a Data Mesh. It assumes that the Data Platform Hub has been deployed and is already operational ready for Nodes to be deployed and connected to it.

### Cloud Environment provisioning

Refer to the diagram for visual representation of the steps

- Step 1: The Azure subscription provisioning is completed by the Cloud Platform Ops team. This should result in a subscription provisioned with the corporate RBAC settings configured ready to be used by the Data Platform Ops.

- Step 2: The Cloud Platform Ops or Data Platform Ops prepares the Data Node environment e.g. connect the Node network to the Hub network, configure service principals in AAD, set-up the DevOps Git repositories.

- Step 3: The main Data Node Git repo is forked to the destination Git repo as well as the creation of CI/CD pipelines/workflows.

- Step 4: Once forked the ARM template parameter files are updated with the values corresponding to the new environment.

- Step 5: The Data Node is deployed using CI/CD workflows newly created.

- Step 6: On demand, the Domain Ops deploy data domain services. This process is done either directly using DevOps tooling or called via pipelines/workflows exposed as APIs. Similarly to the Data Node, it requires first for the code master code repo to be forked.

- Step 7: Because Git code repos are forked, ARM templates can be updated via 'pulls changes' whenever changes occur in the master templates and changes are to be replicated to all Node instances. This requires coordinated activities amongst the teams.

- Step 8: Node Ops can create instance specific ARM templates for the requirements of the project team and deploy them to their Node instance.

- Step 9: On demand, the Data Product Team deploy Data Products. This process is done either directly using DevOps tooling or called via pipelines/workflows exposed as APIs. Similarly to the Data Node and Domain, it requires first for the code master code repo to be forked.

- Step 10: Data Product Team develop their data solutions and deploy them to the Node (DataDevOps, MLOps)

Self-provisioning on-demand is achieved via REST APIs. Applications such as LogicApps, custom UI or PowerApps can be used to create user friendly UI and business approval processes.

![Image](img/WholeProcess.png)

## Appendix

### RACI Chart

||Cloud Environment|DataHub|DataNode|DataDomain|DataProducts|
|-|-|-|-|-|-|
|Data Mesh Service owner|I|A|CI|CI|CI|
|Data Node Service owner|I|CI|A|A|A|
|Cloud Platform Ops|R|C|C|C|C|
|Data Platform Ops|C|R|R|||
|Node Ops|I|R|R|R|R|
|Domain Ops||I|I|R|C|
|Data Products Team||I|I|I|R|
