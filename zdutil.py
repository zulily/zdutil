# example usage:
#
# python zdutil.py -c cluster_config -a setup -s <path_to_script1>,<path_to_script2>
# python zdutil.py -c cluster_config -a teardown

# print list of options:
#
# python zdutil.py -h

from gevent.subprocess import Popen
from gevent import monkey
monkey.patch_all()
import gevent
from string import Template
import argparse
import os.path
import sys
import time
import zdgcutil
import zdgsutil
import setup_env

#control how many parallel calls to make when doing datanode operations like add instance, add disk, etc
BATCH_SIZE = 64

def validate_action(action):
    allowed_actions = {'setup', 'teardown'}
    if action not in allowed_actions:
        print 'Invalid action: {}'.format(action)
        exit(1)

def parse_config(config_file_path):
    config = {}
    with open(config_file_path) as config_file:
        lines = config_file.readlines()

    def add_to_config(tokens):
        if len(tokens) > 1:
            config[tokens[0].strip()] = tokens[1].strip()
    map(lambda line: add_to_config(line.split('=')), lines)
    return config

def validate_config_file(config_file_path):
    if not os.path.isfile(config_file_path):
        print 'Cannot find config file: {}'.format(config_file_path)
        exit(1)

def validate_config(config):
    def check_required(name):
        if not name in config:
            print '{} is required in config file'.format(name)
            exit(1)
    required = ['PREFIX', 'NUM_WORKERS', 'CONFIGBUCKET', 'GCE_ZONE', 'PROJECT', 'DEFAULT_FS',
                'NAMENODE_GCE_MACHINE_TYPE', 'DATANODE_GCE_MACHINE_TYPE',
                'GCE_IMAGE', 'USE_ATTACHED_PDS', 'CREATE_ATTACHED_PDS_ON_DEPLOY', 'DELETE_ATTACHED_PDS_ON_DELETE',
                'WORKER_ATTACHED_PDS_SIZE_GB', 'NAMENODE_ATTACHED_PD_SIZE_GB', 'GCE_SERVICE_ACCOUNT_SCOPES',
                'GCE_NETWORK', 'USER_GCE_SSH_KEY', 'DATANODE_EXTERNAL_IP', 'BDCONFIG',
                'PROJECT', 'INSTALL_ORACLE_JDK', 'INSTALL_JAVA', 'HADOOP_VERSION']
    map(lambda name: check_required(name), required)

def verify(action, config):
    print 'Do you want to {} cluster with the following settings:'.format(action)
    for k, v in config.iteritems():
        print '\t{}: {}'.format(k, v)
    print 'y/n?'
    answer = sys.stdin.readline()
    if not answer or not answer.startswith('y'):
        exit(0)

def validate_script_files(script_file_paths):
    for script_file_path in script_file_paths:
        if not os.path.isfile(script_file_path):
            print 'Cannot find script file: {}'.format(script_file_path)
            exit(1)

def block_and_check_process_output(process_args, fail_on_error=True, retry_count=0):
    process = Popen(process_args)
    process.wait()
    if process.returncode != 0:
        if retry_count > 0:
            print '{} failed. Retrying...'.format(' '.join(process_args))
            block_and_check_process_output(process_args, fail_on_error=fail_on_error, retry_count=retry_count-1)
        else:
            print process.stderr
            if fail_on_error:
                exit(1)

def batch_process(config, func, fail_on_error=True, *func_args):
    num_workers = int(config['NUM_WORKERS'])
    for i in xrange(0, num_workers, BATCH_SIZE):
        processes_args = []
        for j in xrange(i, min(i + BATCH_SIZE, num_workers)):
            processes_args.append(func(j, *func_args))
        jobs = [gevent.spawn(block_and_check_process_output, process_args, fail_on_error=fail_on_error) for process_args in processes_args]
        gevent.joinall(jobs)

def block_until_sshable(config, instance_name, tries=1, wait_time_seconds=10):
    if tries > 10:
        print "Tried {} times to ssh to {}, something bad happened".format(tries, instance_name)
        exit(1)

    process_args = zdgcutil.ssh(config, instance_name)
    process = Popen(process_args)
    process.wait()
    ret_code = process.returncode
    if ret_code != 0:
        print "{} not yet sshable, waiting {} seconds".format(instance_name, wait_time_seconds)
        time.sleep(wait_time_seconds)
        block_until_sshable(config, instance_name, tries + 1)

def block_until_master_sshable(config):
    instance_name = '{}-nn'.format(config['PREFIX'])
    block_until_sshable(config, instance_name)

def create_worker_disks(config):
    def create_worker_disk(i):
        disk_name = '{}-dn-{}-pd'.format(config['PREFIX'], i)
        return zdgcutil.add_disk(config, disk_name, config['WORKER_ATTACHED_PDS_SIZE_GB'])
    batch_process(config, create_worker_disk)

def create_master_disk(config):
    disk_name = '{}-nn-pd'.format(config['PREFIX'])
    process_args = zdgcutil.add_disk(config, disk_name, config['NAMENODE_ATTACHED_PD_SIZE_GB'])
    block_and_check_process_output(process_args)

def create_disks(config):
    if config['USE_ATTACHED_PDS'] == 'true' and config['CREATE_ATTACHED_PDS_ON_DEPLOY'] == 'true':
        create_worker_disks(config)
        create_master_disk(config)

def create_worker_instances(config):
    def create_worker_instance(i):
        optional_disk_arg = None
        if config['USE_ATTACHED_PDS'] == 'true':
            optional_disk_arg = '--disk={}-dn-{}-pd,mode=rw'.format(config['PREFIX'], i)
        instance_name = '{}-dn-{}'.format(config['PREFIX'], i)
        return zdgcutil.add_instance(config, instance_name, optional_disk_arg, config['DATANODE_GCE_MACHINE_TYPE'],
                                     external_ip_address=config['DATANODE_EXTERNAL_IP'])

    batch_process(config, create_worker_instance)

def create_master_instance(config):
    optional_disk_arg = None
    if config['USE_ATTACHED_PDS'] == 'true':
        optional_disk_arg = '--disk={}-nn-pd,mode=rw'.format(config['PREFIX'])
    instance_name = '{}-nn'.format(config['PREFIX'])
    process_args = zdgcutil.add_instance(config, instance_name, optional_disk_arg, config['NAMENODE_GCE_MACHINE_TYPE'])
    block_and_check_process_output(process_args)

def create_instances(config):
    create_worker_instances(config)
    create_master_instance(config)

def tag_instance(instance_name, tags):
    print 'Tagging instance {} with {}'.format(instance_name, ','.join(tags))
    args = ['gcloud',
            'compute',
            'instances',
            'add-tags',
            '--project',
            config['PROJECT'],
            '--zone',
            config['GCE_ZONE'],
            instance_name,
            '--tags']
    return args + tags

def tag_worker_instances(config):
    if 'DATANODE_TAGS' in config:
        tags = config['DATANODE_TAGS'].split(',')
        def tag_worker_instance(i):
            instance_name = '{}-dn-{}'.format(config['PREFIX'], i)
            return tag_instance(instance_name, tags)

        batch_process(config, tag_worker_instance)

def tag_master_instance(config):
    if 'NAMENODE_TAGS' in config:
        tags = config['NAMENODE_TAGS'].split(',')
        instance_name = '{}-nn'.format(config['PREFIX'])
        process_args = tag_instance(instance_name, tags)
        block_and_check_process_output(process_args)

def tag_instances(config):
    tag_master_instance(config)
    tag_worker_instances(config)

def delete_worker_instances(config):
    def delete_worker_instance(i):
        instance_name = '{}-dn-{}'.format(config['PREFIX'], i)
        return zdgcutil.delete_instance(config, instance_name)
    batch_process(config, delete_worker_instance, fail_on_error=False)

def delete_master_instance(config):
    instance_name = '{}-nn'.format(config['PREFIX'])
    process_args = zdgcutil.delete_instance(config, instance_name)
    block_and_check_process_output(process_args, fail_on_error=False)

def delete_instances(config):
    delete_worker_instances(config)
    delete_master_instance(config)

def delete_worker_disks(config):
    def delete_worker_disk(i):
        disk_name = '{}-dn-{}-pd'.format(config['PREFIX'], i)
        return zdgcutil.delete_disk(config, disk_name)
    batch_process(config, delete_worker_disk, fail_on_error=False)

def delete_master_disk(config):
    disk_name = '{}-nn-pd'.format(config['PREFIX'])
    process_args = zdgcutil.delete_disk(config, disk_name)
    block_and_check_process_output(process_args, fail_on_error=False)

def delete_disks(config):
    if config['USE_ATTACHED_PDS'] == 'true' and config['DELETE_ATTACHED_PDS_ON_DELETE'] == 'true':
        delete_worker_disks(config)
        delete_master_disk(config)

def upload_env_script_to_gcs(config):
    #generate the environment script
    template = Template(setup_env.ENV)
    setup_squid = 'true' if config['DATANODE_EXTERNAL_IP'] == 'none' else ''
    env_script = template.substitute(CONFIGBUCKET=config['CONFIGBUCKET'],
                                     NAMENODE_HOSTNAME='{}-nn'.format(config['PREFIX']),
                                     PREFIX=config['PREFIX'],
                                     NUM_WORKERS=config['NUM_WORKERS'],
                                     DEFAULT_FS=config['DEFAULT_FS'],
                                     SETUP_SQUID=setup_squid,
                                     BDCONFIG=config['BDCONFIG'],
                                     PROJECT=config['PROJECT'],
                                     INSTALL_ORACLE_JDK=config['INSTALL_ORACLE_JDK'],
                                     INSTALL_JAVA=config['INSTALL_JAVA'],
                                     HADOOP_VERSION=config['HADOOP_VERSION'])
    env_script_filename = 'setup_env.sh'
    env_script_filepath = '{}/{}'.format(os.path.dirname(os.path.realpath(__file__)), env_script_filename)
    gcs_path = 'cluster_setup/{}/{}'.format(config['PREFIX'], env_script_filename)
    with open(env_script_filepath, 'w') as env_script_file:
        env_script_file.write(env_script)

    #upload it to gcs
    process_args = zdgsutil.copy_file_to_gcs(env_script_filepath, config['CONFIGBUCKET'], gcs_path)
    block_and_check_process_output(process_args)

    #delete it from the local filesystem
    os.remove(env_script_filepath)

    return gcs_path

def upload_ssh_key_to_gcs(config):
    gcs_path = 'cluster_setup/{}/{}'.format(config['PREFIX'], 'temp')
    process_args = zdgsutil.copy_file_to_gcs(config['USER_GCE_SSH_KEY'], config['CONFIGBUCKET'], gcs_path)
    block_and_check_process_output(process_args)
    return gcs_path

def run_remote_setup(config):
    #upload env script to GCS
    env_script_gcs_path = upload_env_script_to_gcs(config)
    instance_name = '{}-nn'.format(config['PREFIX'])

    #upload the setup scripts to GCS
    setup_scripts_gcs_path = 'cluster_setup'
    setup_scripts_filepath = '{}/{}'.format(os.path.dirname(os.path.realpath(__file__)), 'libexec/*.sh')
    process_args = zdgsutil.copy_file_to_gcs(setup_scripts_filepath, config['CONFIGBUCKET'], setup_scripts_gcs_path)
    block_and_check_process_output(process_args)

    #upload the config files to GCS
    config_files_gcs_path = 'cluster_setup'
    conf_path = 'hadoop1_conf' if config['HADOOP_VERSION'] == '1.x' else 'hadoop2_conf'
    config_files_filepath = '{}/{}'.format(os.path.dirname(os.path.realpath(__file__)), '{}/*.xml'.format(conf_path))
    process_args = zdgsutil.copy_file_to_gcs(config_files_filepath, config['CONFIGBUCKET'], config_files_gcs_path)
    block_and_check_process_output(process_args)

    #copy the env script the namenode
    copy_env_script_cmd = 'gsutil cp gs://{}/{} .'.format(config['CONFIGBUCKET'], env_script_gcs_path)
    process_args = zdgcutil.remote_command(config, instance_name, copy_env_script_cmd)
    block_and_check_process_output(process_args)

    #copy the setup scripts to the namenode
    copy_setup_scripts_cmd = 'gsutil cp gs://{}/cluster_setup/*.sh .'.format(config['CONFIGBUCKET'])
    process_args = zdgcutil.remote_command(config, instance_name, copy_setup_scripts_cmd)
    block_and_check_process_output(process_args)

    #copy the config files to the namenode
    copy_conf_files_cmd = 'gsutil cp gs://{}/cluster_setup/*.xml .'.format(config['CONFIGBUCKET'])
    process_args = zdgcutil.remote_command(config, instance_name, copy_conf_files_cmd)
    block_and_check_process_output(process_args)
    process_args = zdgcutil.remote_command(config, instance_name, 'chmod +x ./*.sh')
    block_and_check_process_output(process_args)

    #upload the private key for GCS to the namenode, so that it can ssh to all the datanodes
    ssh_key_gcs_path = upload_ssh_key_to_gcs(config)
    process_args = zdgcutil.remote_command(config, instance_name, 'rm -f temp')
    block_and_check_process_output(process_args)
    copy_ssh_key_cmd = 'gsutil cp gs://{}/{} .'.format(config['CONFIGBUCKET'], ssh_key_gcs_path)
    process_args = zdgcutil.remote_command(config, instance_name, copy_ssh_key_cmd)
    block_and_check_process_output(process_args)
    process_args = zdgcutil.remote_command(config, instance_name, 'chmod 400 temp')
    block_and_check_process_output(process_args)

    #configure the namenode and datanodes
    process_args = zdgcutil.remote_command(config, instance_name, 'sudo bash setup_namenode_all.sh > provision.log 2>&1')
    block_and_check_process_output(process_args)

def run_extra_scripts(script_file_paths):
    if script_file_paths:
        instance_name = '{}-nn'.format(config['PREFIX'])

        for script_file_path in script_file_paths:
            script_file_name = os.path.basename(script_file_path)

            #upload the script to GCS
            gcs_path = 'cluster_setup/extras/{}'.format(script_file_name)
            process_args = zdgsutil.copy_file_to_gcs(script_file_path, config['CONFIGBUCKET'], gcs_path)
            block_and_check_process_output(process_args)

            #copy the script from GCS to the namenode
            copy_script_cmd = 'gsutil cp gs://{}/{} .'.format(config['CONFIGBUCKET'], gcs_path)
            process_args = zdgcutil.remote_command(config, instance_name, copy_script_cmd)
            block_and_check_process_output(process_args)

            #make sure the script is executable
            command = 'chmod +x {}'.format(script_file_name)
            process_args = zdgcutil.remote_command(config, instance_name, command)
            block_and_check_process_output(process_args)

            #run the script on the namenode
            command = 'sudo bash {} > {}.log 2>&1'.format(script_file_name, script_file_name)
            process_args = zdgcutil.remote_command(config, instance_name, command)
            block_and_check_process_output(process_args)

def setup(config, script_file_paths, prompt=True):
    if prompt:
        verify(action, config)
    validate_script_files(script_file_paths)
    create_disks(config)
    create_instances(config)
    tag_instances(config)
    block_until_master_sshable(config)
    run_remote_setup(config)
    namenode = '{}-nn'.format(config['PREFIX'])
    print 'Successfully created cluster.'
    print 'Namenode: {}'.format(namenode)
    for i in range(int(config['NUM_WORKERS'])):
        print 'Datanode {}: {}'.format(i, '{}-dn-{}'.format(config['PREFIX'], i))

    run_extra_scripts(script_file_paths)

def teardown(config, prompt=True):
    if prompt:
        verify(action, config)
    delete_instances(config)
    delete_disks(config)

parser = argparse.ArgumentParser(description='''Utility for creating a GCE cluster and installing, configuring,
and calling Hadoop and Hadoop compatible software on it.''')

parser.add_argument('-c',
                    dest='config_file',
                    required=True,
                    help='Describes the cluster configuration')

parser.add_argument('-a',
                    dest='action',
                    required=True,
                    help='The action to take, setup or teardown')

parser.add_argument('-f',
                    action='store_true',
                    default=False,
                    dest='force',
                    help='Disable user prompts')

parser.add_argument('-s',
                    dest='scripts',
                    required=False,
                    help='Comma delimited list of scripts to run after cluster is provisioned')

args = parser.parse_args()

action = args.action
validate_action(action)
config_file_path = args.config_file
validate_config_file(config_file_path)
config = parse_config(config_file_path)
validate_config(config)

script_file_paths = []
if args.scripts:
    script_file_paths = args.scripts.strip().split(',')

if action == 'setup':
    setup(config, script_file_paths, prompt=not args.force)

elif action == 'teardown':
    teardown(config, prompt=not args.force)
