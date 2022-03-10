class ScriptParserNotCreatedError(Exception):
    def __init__(self, msg):
        super().__init__(msg)


class MissingEnvironmentVariable(Exception):
    def __init__(self, msg):
        super().__init__(msg)
