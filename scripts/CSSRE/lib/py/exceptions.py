class ScriptParserNotCreatedError(Exception):
    def __init__(self, msg):
        super().__init__(msg)


class MissingEnvironmentVariable(Exception):
    def __init__(self, msg):
        super().__init__(msg)


class StatefulsetExecConnectionError(Exception):
    def __init__(self, msg):
        details = "This can happen if there are no pods in the statefulset in a ready state or a pod restarted during the process. Ensure there are ready pods and try again."
        super().__init__(msg, details)

class NotManagedKafkaNamespace(Exception):
    def __init__(self, msg):
        details = "The selected namespace is not a Kafka namespace"
        super().__init__(msg, details)
