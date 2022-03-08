import sys
import json

from py.logger import Logger
from py.command import Command
from py.exceptions import ScriptParserNotCreatedError

from tabulate import tabulate as tb


class Script:
    def __init__(self,
                 logger_name=__name__,
                 run_now=True):
        self._parser = None
        self.args = self.parse_args()

        if not hasattr(self.args, "log_level"):
            setattr(self.args, "log_level", "info")

        Logger(name=logger_name, level=self.args.log_level)
        self.logger = Logger.get_logger(logger_name)

        self.cmd = Command(logger_name=logger_name)

        if run_now:
            exit(self.run())

    @property
    def parser(self):
        return self._parser

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
