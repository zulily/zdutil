#!/bin/bash

echo '#!/bin/bash' >> /etc/init.d/restart_namenode.sh
echo '#/etc/init.d/restart_namenode.sh' >> /etc/init.d/restart_namenode.sh
echo "su - hadoop ${HADOOP_INSTALL_DIR}"/bin/start-all.sh >> /etc/init.d/restart_namenode.sh
chown hadoop: /etc/init.d/restart_namenode.sh
chmod +x /etc/init.d/restart_namenode.sh
update-rc.d restart_namenode.sh defaults
