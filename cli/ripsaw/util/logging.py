import logging

class DuplicateFilter(logging.Filter):
    def filter(self, record):
        # add other fields if you need more granular comparison, depends on your app
        current_log = (record.module, record.levelno, record.msg)
        if current_log != getattr(self, "last_log", None):
            self.last_log = current_log
            return True
        return False

logging.basicConfig(level=logging.INFO, format='ripsaw-cli:%(name)s:%(levelname)s :: %(message)s')
logger = logging.getLogger()  # get the root logger
logger.addFilter(DuplicateFilter())

def get_logger(name):
    logger = logging.getLogger(name)
    logger.addFilter(DuplicateFilter())
    return logger

 



