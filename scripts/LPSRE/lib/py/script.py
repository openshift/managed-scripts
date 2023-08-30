import sys
import json
import os
import openshift

from py.logger import Logger
from py.command import Command
from py.exceptions import ScriptParserNotCreatedError
from py.exceptions import MissingEnvironmentVariable
import py.settings as settings

from tabulate import tabulate as tb


class Script:
    def __init__(self,
                 logger_name=__name__,
                 run_now=True,
                 env_vars=None,
                 check_env_var=True):

        if env_vars is not None:
            envs = EnvironmentVariableInjector(self,
                                               check_env_var=check_env_var)
            for v in env_vars:
                envs.add(v)

        self._parser = None
        self.args = self.parse_args()

        if hasattr(self, "LOG_LEVEL"):
            setattr(self.args, "log_level", self.LOG_LEVEL)
        elif not hasattr(self.args, "log_level"):
            setattr(self.args, "log_level", "info")

        Logger(name=logger_name, level=self.args.log_level)
        self.logger = Logger.get_logger(logger_name)

        self.cmd = Command(logger_name=logger_name)
        self._oc = openshift
        self.settings = settings

        if run_now:
            exit(self.run())

    @property
    def parser(self):
        return self._parser
    
    @property
    def oc(self): 
        return self._oc

    @parser.setter
    def parser(self, value):
        self._parser = value

    def parse_args(self):
        self.create_parser()

        if self._parser is None:
            raise ScriptParserNotCreatedError(
                "Create parser by implementing Script.create_parser")

        return self._parser.parse_args()

    def create_parser(self):
        raise NotImplementedError

    def run(self):
        raise NotImplementedError

    def exit(self, code):
        sys.exit(code)

    @property
    def silent(self):
        return self._silent

    @silent.setter
    def silent(self, value):
        self._silent = value

    def print_json(self, value):
        if not self.silent:
            print(json.dumps(value, indent=2))
        return value

    def print_table(self, rows, headers):
        print(tb(rows, headers=headers))

class EnvironmentVariableInjector:
    def __init__(self, target, check_env_var=True):
        self._target = target
        self._check_env_var = check_env_var

    def add(self, name):
        try:
            setattr(self._target, name, os.environ[name])
        except KeyError:
            if self._check_env_var:
                raise MissingEnvironmentVariable(
                    f"Missing environment variable: {name}")
            else:
                setattr(self._target, name, None)
