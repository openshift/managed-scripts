import logging


class Logger:
    def __init__(self, level, name=__name__):
        if level == "debug":
            _level = logging.DEBUG
        elif level == "warning":
            _level = logging.WARNING
        elif level == "error":
            _level = logging.ERROR
        else:
            _level = logging.INFO

        self.init(_level)

    def init(self, level):
        logging.basicConfig(
            level=level,
            format=('%(asctime)s.%(msecs)03d '
                    '%(levelname)-2s '
                    '(%(name)-s):  %(message)s')
        )

    @staticmethod
    def get_logger(name):
        return logging.getLogger(name)
