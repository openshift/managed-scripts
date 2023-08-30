class ScriptParserNotCreatedError(Exception):
    def __init__(self, msg):
        super().__init__(msg)


class MissingEnvironmentVariable(Exception):
    def __init__(self, msg):
        super().__init__(msg)


class ServiceExecConnectionError(Exception):
    def __init__(self, msg):
        details = "This most likely can happen if there are no pods reached by the service in a ready state or a pod restarted during the process. Ensure there are ready pods and try again. This can also happen if the bootstrap server for the service does not exist/cannot be reached."
        super().__init__(msg, details)

class NotManagedKafkaNamespace(Exception):
    def __init__(self, msg):
        details = "The selected namespace is not a Kafka namespace"
        super().__init__(msg, details)