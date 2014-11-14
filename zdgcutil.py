from subprocess import Popen

def add_disk(config, disk_name, size_in_gb):
    print 'Creating disk: {}'.format(disk_name)
    args = ['gcutil',
            'adddisk',
            '--project={}'.format(config['PROJECT']),
            '--zone={}'.format(config['GCE_ZONE']),
            '--size_gb={}'.format(size_in_gb),
            disk_name]
    return Popen(args)

def add_instance(config, instance_name, optional_disk_arg, external_ip_address='ephemeral'):
    print 'Creating instance: {}'.format(instance_name)
    args = ['gcutil',
            'addinstance',
            '--project={}'.format(config['PROJECT']),
            '--zone={}'.format(config['GCE_ZONE']),
            '--machine_type={}'.format(config['GCE_MACHINE_TYPE']),
            '--service_account=default',
            '--image={}'.format(config['GCE_IMAGE']),
            '--network={}'.format(config['GCE_NETWORK']),
            '--service_account_scopes={}'.format(config['GCE_SERVICE_ACCOUNT_SCOPES']),
            '--persistent_boot_disk',
            '--external_ip_address={}'.format(external_ip_address)]
    if optional_disk_arg:
        args.append(optional_disk_arg)
    args.append(instance_name)
    return Popen(args)

def delete_instance(config, instance_name):
    args = ['gcutil',
            'deleteinstance',
            '--project={}'.format(config['PROJECT']),
            '--zone={}'.format(config['GCE_ZONE']),
            '--force',
            '--delete_boot_pd',
            instance_name]
    return Popen(args)

def delete_disk(config, disk_name):
    args = ['gcutil',
            'deletedisk',
            '--project={}'.format(config['PROJECT']),
            '--zone={}'.format(config['GCE_ZONE']),
            '--force',
            disk_name]
    return Popen(args)

def remote_command(config, instance_name, command):
    args = ['gcutil',
            '--project={}'.format(config['PROJECT']),
            'ssh',
            instance_name,
            command]
    return Popen(args)

def ssh(config, instance_name):
    return remote_command(config, instance_name, 'exit 0')
