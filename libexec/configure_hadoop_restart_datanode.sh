#!/bin/bash

echo '#!/bin/bash' >> /etc/init.d/restart_datanode.sh
echo '#/etc/init.d/restart_datanode.sh' >> /etc/init.d/restart_datanode.sh
echo "su - hadoop ${HADOOP_INSTALL_DIR}"/bin/hadoop-daemon.sh start tasktracker >> /etc/init.d/restart_datanode.sh
echo "su - hadoop ${HADOOP_INSTALL_DIR}"/bin/hadoop-daemon.sh start datanode >> /etc/init.d/restart_datanode.sh
chown hadoop: /etc/init.d/restart_datanode.sh
chmod +x /etc/init.d/restart_datanode.sh
update-rc.d restart_datanode.sh defaults
