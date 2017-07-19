# cr-pipeline-scripts
Scripts to build and deploy CR using the pipeline.

### To use the blue-green deployment scripts:

- Make sure the Application Name field is set on the Pipeline stage so that CF_APP will be defined.
- All Pipeline stage environment variables will be set as environment variables in the CF app.
- To bind services to the CF app, put the service names in and environment variables named SERVICE_NAMES separated with commas and no spaces.
- Basic testing to check if the TEST_PATH returns a 200 status is dones. You may set TEST_STATUS_PASS to check that the JSON returned has a 'PASS' status or TEST_STATUS_NUMERIC to check that the JSON status is 0 and not 1.


``` sh
#!/bin/bash
export PATH=/opt/IBM/node-v6.2.2/bin:$PATH

export DOMAIN=mybluemix.net
export TEST_PATH=api/v1/status
export INSTANCES=1
export MEMORY=256M

git clone --depth=1 https://github.com/rws-github/cr-pipeline-scripts.git ../cr-pipeline-scripts
chmod +x ../cr-pipeline-scripts/blue-green/*.sh

. ../cr-pipeline-scripts/blue-green/all.sh
```



### To use the Cloudant design document init scripts:

``` sh
#!/bin/bash
export PATH=/opt/IBM/node-v6.2.2/bin:$PATH

export CLOUDANT_URL=...
export CLOUDANT_DB=...
export DESIGN_DIR=`pwd`/design

git clone --depth=1 https://github.com/rws-github/cr-pipeline-scripts.git ../cr-pipeline-scripts
chmod +x ../cr-pipeline-scripts/cloudant/*.sh

../cr-pipeline-scripts/cloudant/init.sh
```



### The two above combined:

``` sh
#!/bin/bash
export PATH=/opt/IBM/node-v6.2.2/bin:$PATH

export DOMAIN=mybluemix.net
export TEST_PATH=api/v1/status
export INSTANCES=1
export MEMORY=256M
export DESIGN_DIR=`pwd`/design

git clone --depth=1 https://github.com/rws-github/cr-pipeline-scripts.git ../cr-pipeline-scripts
chmod +x ../cr-pipeline-scripts/blue-green/*.sh
chmod +x ../cr-pipeline-scripts/cloudant/*.sh

../cr-pipeline-scripts/cloudant/init.sh
. ../cr-pipeline-scripts/blue-green/all.sh
```