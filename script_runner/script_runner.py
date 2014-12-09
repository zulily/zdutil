# example usage:
# python script_runner.py -c cluster_config -z <path_to_zdutil> -s <path_to_script1>,<path_to_script2>

import argparse
from subprocess import Popen
import os

def block_and_check_process_output(process_args,
                                   fail_on_error=True,
                                   retry_count=3,
                                   pre_retry_fn=None,
                                   on_fail_fn=None):
    process = Popen(process_args)
    process.wait()
    if process.returncode != 0:
        if retry_count > 0:
            print '{} failed. Retrying...'.format(' '.join(process_args))
            if pre_retry_fn:
                pre_retry_fn()
            block_and_check_process_output(process_args,
                                           fail_on_error=fail_on_error,
                                           retry_count=retry_count - 1,
                                           pre_retry_fn=pre_retry_fn,
                                           on_fail_fn=on_fail_fn)
        else:
            print process.stderr
            if on_fail_fn:
                on_fail_fn()
            if fail_on_error:
                exit(1)

def parse_command_line_args():
    parser = argparse.ArgumentParser(description='''Utility to provision a Hadoop cluster on GCE, run one or more scripts on the namenode,
    and delete the cluster afterwards.''')

    parser.add_argument('-c',
                        dest='config_file',
                        required=True,
                        help='Describes the cluster configuration')

    parser.add_argument('-z',
                        dest='zdutil',
                        required=True,
                        help='Full path to zdutil')


    parser.add_argument('-s',
                        dest='scripts',
                        required=True,
                        help='Comma delimited list of scripts to run after cluster is provisioned')

    return parser.parse_args()

def provision_cluster(args):
    provision_args = ['python',
                      args.zdutil,
                      '-c',
                      args.config_file,
                      '-a'
                      'setup',
                      '-f',
                      '-s', args.scripts]
    def teardown():
        teardown_cluster(args)

    block_and_check_process_output(provision_args,
                                   retry_count=5,
                                   pre_retry_fn=teardown,
                                   on_fail_fn=teardown)

def teardown_cluster(args):
    provision_args = ['python',
                      args.zdutil,
                      '-c',
                      args.config_file,
                      '-a'
                      'teardown',
                      '-f']
    block_and_check_process_output(provision_args)

def validate_zdutil(args):
    if not os.path.isfile(args.zdutil):
        print 'Cannot find zdutil.py at: {}'.format(args.zdutil)
        exit(1)

    if os.path.basename(args.zdutil) != 'zdutil.py':
        print 'Cannot find zdutil.py at: {}'.format(args.zdutil)
        exit(1)

args = parse_command_line_args()
validate_zdutil(args)
provision_cluster(args)
teardown_cluster(args)
