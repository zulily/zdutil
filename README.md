zdutil
================================

Tool for provisioning GCE hadoop clusters.

Getting started
-------------------------
* Install gevent
```bash
sudo pip install gevent
```

* Follow the instructions to install and configure gsutil at: https://cloud.google.com/storage/docs/gsutil_install

* Follow the instructions to install and configure gcutil at: https://cloud.google.com/compute/docs/gcutil

* Copy cluster_config_sample to cluster_config
```bash
cp cluster_config_sample cluster_config
```

* Edit the settings in the custom settings section of cluster_config

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

To setup a Hadoop cluster and run your own bash scripts on the namenode
-------------------------
```bash
python zdutil.py -c cluster_config -a setup -s <path_to_script1>,<path_to_script2>
```

To setup a Hadoop cluster, run your own bash scripts on the namenode, and teardown the cluster afterwards
-------------------------
```bash
python script_runner/script_runner.py -c cluster_config -z zdutil.py -s <path_to_script1>,<path_to_script2>
```

Details
-------------------------
Read more about zdutil at http://engineering.zulily.com/2014/12/03/google-compute-engine-hadoop-clusters-with-zdutil/