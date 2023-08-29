Car Sales Dashboard with AWS, Terraform, Mage, dlt, dbt, Soda, and Metabase

I. Introduction

This project aims to create a sales dashboard with the use of AWS together with a set of open-source software. The entire project will be built on top of AWS infrastructure through the use of ALB, ECS, EFS, RDS, Secrets Manager, and VPC. Terraform will be used to initialize and destroy the AWS services for this project.

The extraction and loading of source data will be done through dlt while the transformations will be executed through dbt. Soda will be utilized for the data quality checks. The entire pipeline will be orchestrated through Mage and the sales dashboard will be presented through Metabase.

NOTES:
* This project will use a mock source database. This is from a separate project which was inspired by this project.
* Implementation of this project will incur costs on AWS. If you proceed with this project, take note of the costs incurred and ensure that all services are removed/deleted once finished.

II. Pre-requisites

* AWS Access Key and Secret Access Key
* Terraform CLI
    * Link: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
* Terraform Cloud account and RDS Database filled with fake values based on the mock source database project. Ensure that the RDS Database in this project has the generated values and is running.
    * Link: https://medium.com/@aleckbowenromero/mock-sales-database-with-docker-faker-jupyterlab-and-postgres-b1b677eb6184
* Create another workspace in Terraform Cloud which should be different from the one used for the mock source database project. Ensure that the AWS Access and Secret Access Keys are accessible for this workspace.
* Git
    * Link: https://git-scm.com/downloads

III. Installation

* Clone the Git repository for the Terraform scripts
    * Link: PUT LINK OF THE PUBLIC REPO HERE
* The scripts for dlt, dbt, and Soda will be cloned later inside the Mage container. No need to clone these files in your local directory.

IV. Brief Explanation of AWS Services for This Project

This project will highlight the use of AWS ECS to host the Mage and Metabase containers. These services will require their separate EFS volumes and RDS databases to store metadata. Application Load Balancers and Auto Scaling Groups will also be used for ECS to manage the incoming traffic for this applications.

All of the RDS databases used in this project will also use AWS Secrets Manager to handle the username and passwords for this project.

All of these applications will be housed inside a VPC with public and private subnets attached. Two availability zones will be used. Private subnets will utilize elastic IPs and NAT Gateways for the containers to communite with the Internet. For the containers to be accessed from the Internet, as mentioned already, Application Load Balancers will also be used.


IV. Creation of AWS resources

Before the initialization of AWS resources, ensure that your Terraform Cloud account has the AWS Access and Secret Access Keys loaded as variables. Ensure as well that these variables can be accessed from your Terraform workspace. Refer to the mock source database project with the link above for reference.

* Inside the "main" folder in the cloned repo, replace the values in the cloud block (line 18 and 20) with the organization and workspace values you created in Terraform cloud.
* Set the working directory in your CLI to the "main" folder where you cloned the Terraform scripts.
* Enter the following command:
    * terraform init
* Once the initialization completes, enter the following command:
    * terraform plan
* If everything works perfectly, enter the next command:
    * terraform apply -auto-approve

If everything works well, you will get a confirmation saying that all resources are created.

VI. Access to the AWS Resources

Only two of the ECS clusters inside need to be accessed. The other services created from the Terraform scripts will be used by the applications running on ECS for metadata. The main RDS database will be accessed indirectly by Metabase.

* Mage
    * Go to the ECS page on your AWS Account 
    * In the "Clusters" page, click "mage_cluster"
    * In the "Services" tab, click "mage-ecs-service"
    * In the "Health and metrics" tab, click the "View load balancer" button
    * Once the new page opens, copy the DNS name of the load balancer by clicking the two small boxes.
    * Open a new tab in your browser and paste the DNS name.

* Metabase
    * Go to the ECS page on your AWS Account 
    * In the "Clusters" page, click "metabase_cluster"
    * In the "Services" tab, click "metabase-ecs-service"
    * In the "Health and metrics" tab, click the "View load balancer" button
    * Once the new page opens, copy the DNS name of the load balancer by clicking the two small boxes.
    * Open a new tab in your browser and paste the DNS name.


VII. Implementing dlt, dbt, and Soda scripts inside Mage

We will load the dlt, dbt, and Soda scripts inside Mage by cloning a Git repo. Follow the steps below to setup the scripts.
* In the Mage console, click the Terminal button on the lower left of the page and enter the following commands:
    * git clone https://github.com/abwromero/mage-docs.git
    * mv mage-docs default_repo
* Go to the "mage-docs" folder, open the "global" folder, and click the "requirements.txt" file.
    * Copy or enter the last line in the file in the Mage Terminal: pip3 install -i https://pypi.cloud.soda.io soda-core-postgres sqlalchemy>=1.4 dbt-postgres dlt dlt[postgres]
* Enter the following commands in the Terminal individually to check if the packages were installed properly. The packages were installed properly if their respective lists of commands are shown in the Terminal.
    * dlt
    * dbt
    * soda
* Enter the following command in Terminal with the present working directory at "/home/src"
    * dlt init sql_database postgres
    * When asked about the creation of the dlt files, enter "Y"
* In the Mage Terminal with the present working directory at "/home/src", enter the following command
    * dbt init car_sales_dashboard
    * When asked for the database to be used, enter "7" for Postgres.
* Move the "car_sales_dashboard" folder inside /home/src/default_repo/dbt.
    * mv car_sales_dashboard /home/src/default_repo/dbt
* Change your working directory to the "dbt" folder inside "mage-docs"
    * cd default_repo/mage-docs/dbt
* Move the 3 YAML files from this folder to the "car_sales_dashboard" folder of "default_repo/dbt"
    * mv dbt_project.yml packages.yml profiles.yml /home/src/default_repo/dbt/car_sales_dashboard
* Move all of the contents of "models" to "default_repo/dbt/car_sales_dashboard/models"
    * mv models/* /home/src/default_repo/dbt/car_sales_dashboard/models
* Set the working directory to "/home/src/default_repo/dbt/car_sales_dashboard and enter the following command
    * dbt deps

VIII. Creation of the Pipeline

After all of the files have been moved to their respective folders, we will now start the creation of the pipeline.
* Click the "Overview" button on the top left of the page and click "+ New Pipeline"
* Select "Standard (batch)", click the created pipeline, and select "Edit Pipeline"

We will now create the blocks for the pipeline
* In the "Edit" page, click "Data loader" with "Python" and "Generic" as the choices. Name the block "dlt_postgres_loader". Remove all of the contents inside the script and paste the code from "dlt-loader.py" in the "dlt" folder from "mage-docs"
* Click "Custom" below the block and select "Python" with the color "Blue". Name the block "soda_source_check". Remove the default contents and paste the contents from "soda_source_check.py" in "default_repo/mage-docs/python scripts".
* Click "DBT model" below the latest block and select "Single model or snapshot (from file)". Select "stg_src__values.sql" from "car_sales_dashboard/models/staging"
* Click "DBT model" below the last DBT model block and select "Single model or snapshot (from file)". Select "int_src_customers_cleaned.sql" from "car_sales_dashboard/models/intermediate"
* Click "DBT model" below the last DBT model block and select "Single model or snapshot (from file)". Select "int_src_vehicles_cleaned.sql" from "car_sales_dashboard/models/intermediate"
* Click "DBT model" below the last DBT model block and select "Single model or snapshot (from file)". Select "int_src_sales_condensed.sql" from "car_sales_dashboard/models/intermediate"
* Click "Custom" below the last DBT model and select "Python" with the color "Blue". Name the block "soda_intermediate_customers_check" and remove the default contents. Paste in this block the values from "soda_intermediate_customers_check.py" from "default_repo/mage-docs/python scripts"
* Click "Custom" below the last custom block and select "Python" with the color "Blue". Name the block "soda_intermediate_vehicles_check" and remove the default contents. Paste in this block the values from "soda_intermediate_vehicles_check.py" from "default_repo/mage-docs/python scripts"
* Click "Custom" below the last custom block and select "Python" with the color "Blue". Name the block "soda_intermediate_sales_check" and remove the default contents. Paste in this block the values from "soda_intermediate_sales_check.py" from "default_repo/mage-docs/python scripts"
* Finally, select "DBT model" below the last custom block. Select "Single model or snapshot (from file)". Select "sales.sql" from "car_sales_dashboard/models/marts".

We will arrange the dependencies of the blocks with the tree UI
* Click the small arrow icon on the top right of the page. Make sure you selected the tree button.
* Arrange the dependencies based on the image below.
* Click and drag the lines to connect the blocks.
* To set downstream dependencies from a block, hover to that block, click and hold the circle below it, and drag the line on top of the downstream block.
* Likewise, to set upstream dependencies, hover to that block, click and hold the circle at the top, and drag the line to the bottom of the upstream block.

We will now fill up the credentials required by dlt to load the data from the external database to the internal database.
* Fill up the values in the "secrets.yml" file inside "mage-docs/dlt". Note that the values required to fill up the details can be found in the RDS database details and AWS Secrets Manager.
* The host is the endpoint of the RDS Database.
* The value for "database" should be the "DB name" as seen from the "Configuration" tab.
* Ports of both source and destination should be 5432.
* Username and password of both databases should be seen from AWS Secrets Manager. To know which username and password combination is correct, the username in the AWS Secrets Manager should match the "Master username" in the "Configuration" tab of the database.
* Save the file and rename the filr from "secrets.yml" to "secrets.toml".

We will now set the credentials for the dbt to modify the data inside the internal database.
* Go to "default_repo/dbt/car_sales_dashboard" and select "profiles.yml". Enter the credentials of the internal database.
* "target" should be left at "dev"
* "type" should be left at "postgres"
* "host" is the RDS endpoint
* "user" is the username from AWS Secrets Manager
* "password" is the password from AWS Secrets Manager
* "port" should be left at 5432
* "dbname" is the "DB name" at the "Configuration" tab of the database.
* "schema" should be left at "dev"
* Save the file

* Go to "default_repo/dbt/car_sales_dashboard/models" and select "sources.yml". Enter the following details.
* "name" should be the "DB name" of the database
* "database" should be the "DB name" of the database
* "schema" should be left at "dev"
* "tables.name" and "tables.name.identifier" should be left at "raw_values"
* Save the file

* Go to the "stg_src__values.sql" file at "default_repo/dbt/staging" and modify the data
* In the 12th line, replace "main" with the name of the internal database.

We will also set the credentials for Soda to run the data quality tests inside the internal database.
* Open the file "configuration.yml" from "default_repo/mage-docs/soda" and modify the details
* "type" should be left at "postgres"
* "connection.host" should be the endpoint of the RDS database
* "connection.username" should be the username from AWS Secrets Manager
* "connection.password" should be the password from AWS Secrets Manager
* "database" should be the "DB name" from the "Configuration" tab from the database
* "schema" should be left at "dev"

After all of the modifications, run the pipeline
* Go back to the pipeline edit window and save the file
* Click the name of the pipeline and select "Run pipeline now" on the right side of the screen"

XI. Sales Dashboard with Metabase

Open the Metabase page and fill up the details required
* Choose the language you prefer
* Fill up the details requiring your personal information
* In the data part, fill up the following details
* For the "Display name", enter "Car Sales"
* For the "Host", enter the RDS Endpoint
* "Port" should be 5432
* "Database name" is the same as the "DB name" in the "Configuration" tab of your database.
* "Username" is the same as the username seen from AWS Secrets Manager
* "Password" is the same as the password seen from AWS Secrets Manager

After filling up the details, click "Connect database"

You will be asked about "Usage data preferences", choose what fits your preferences.

We will now open the database through Metabase
* On the "Home" page, click "Browse data" on the left side and then click "Car Sales"
* Choose the "dev_visualization" folder and select "Sales"

At this point, the method of visualization depends on your requirements, but here is a sample dashboard based from the processed data from the ELT.

X. Stop and remove AWS infrastructure on Terraform
* IMPORTANT: Stop all of the services on AWS to prevent any additional costs. To shutdown the AWS services started through Terraform, run the following command:
    * "terraform destroy -auto-approve"
* Ensure that the process reaches completion and without errors. 

XI. Final Notes
* If there are errors or areas this project can improve on, please let me know.

XII. References

Faker documentation:
https://faker.readthedocs.io/en/master/

Loading Data from Python to Postgres:
https://hakibenita.com/fast-load-data-python-postgresql 

Purpose of "seek" in loading data from Python to Postgres:
https://stackoverflow.com/questions/55181331/bulk-insert-using-postgresql-copy-from-psycopg2-and-stringio

Use of copy_expert instead of copy_from:
https://github.com/psycopg/psycopg2/issues/1294

Postgres COPY syntax:
https://www.postgresql.org/docs/current/sql-copy.html

List of vehicles source (vehicle data copied and processed manually):
https://www.carguide.ph/p/philippine-car-price-guide-2016_18.html

DevOps Bootcamp: Terraform by Andrei Neagoie and Andrei Dumitrescu:
https://www.udemy.com/course/devops-bootcamp-terraform-certification/