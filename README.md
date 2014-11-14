zdutil
================================

Tool for provisioning GCE hadoop clusters.

Getting started
-------------------------
1. Follow the instructions to install and configure gsutil at: https://cloud.google.com/storage/docs/gsutil_install

2. Follow the instructions to install and configure gcutil at: https://cloud.google.com/compute/docs/gcutil

3. Copy cluster_config_sample to cluster_config
```bash
cp cluster_config_sample cluster_config
```

4. Edit the settings in the custom settings section of cluster_config

To setup a Hadoop cluster
-------------------------
```bash
python zdutil.py -c cluster_config -a setup
```

To teardown a Hadoop cluster
-------------------------
```bash
python zdutil.py -c cluster_config -a teardown
```

Details
-------------------------
Read more about zdutil at http://engineering.zulily.com/category/relevancy-and-personalization/