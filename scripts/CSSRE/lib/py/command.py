import os
import sys
import subprocess as sp

from py.logger import Logger


class Command:
    def __init__(self, logger_name=__name__):
        self.logger = Logger.get_logger(logger_name)

    def run_output(self, cmd, check=True, cwd=None, quiet=False):
        self.logger.debug(f'Running command "{cmd}"')

        if not quiet:
            sp.run(cmd, stdout=sys.stdout, stderr=sys.stderr, check=check, cwd=cwd)
        else:
            sp.run(cmd, stdout=sp.DEVNULL, stderr=sp.DEVNULL, check=check, cwd=cwd)

    def run_pipe(self, cmd, check=True, input=None, cwd=None):
        self.logger.debug(f'Running command "{cmd}"')

        if input is not None:
            res = sp.run(cmd, stdout=sp.PIPE, stderr=sp.PIPE, check=check, input=input)
        else:
            res = sp.run(cmd, stdout=sp.PIPE, stderr=sp.PIPE, check=check)

        stdout = res.stdout.decode('utf-8')
        stderr = res.stderr.decode('utf-8')
        return res.returncode, stdout, stderr

    def run_output_from_list(self, cmds, check=True, cwd=None):
        for cmd in cmds:
            self.run_output(cmd, check=check, cwd=cwd)

    def run_script_non_blocking(self, script_cmd, check=True, env=None):
        self.logger.debug(f"Running script {script_cmd}")

        all_env = os.environ.copy()

        if env is not None:
            all_env.update(env)

        sp.Popen(script_cmd, start_new_session=True, env=all_env)
