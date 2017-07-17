# cr-pipeline-scripts
Scripts to build and deploy CR using the pipeline.


### To use the blue-green deployment scripts:

Make sure the Application Name field is set on the Pipeline stage so that CF_APP will be defined.

``` sh
#!/bin/bash
export PATH=/opt/IBM/node-v6.2.2/bin:$PATH

export DOMAIN=stage1.mybluemix.net
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
export CLOUDANT_DB=release-events-stage1
export DESIGN_DIR=`pwd`/deploy/design

git clone --depth=1 https://github.com/rws-github/cr-pipeline-scripts.git ../cr-pipeline-scripts
chmod +x ../cr-pipeline-scripts/cloudant/*.sh

../cr-pipeline-scripts/cloudant/init.sh
```