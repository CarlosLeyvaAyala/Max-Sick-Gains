# The master server has a list of all individual servers and
# coordinates loading/saving files, cascade deleting records
# and such things.

from nutsbolts.DataServer.FitnessLvlDataServer import FitnessLvlDataServer
from tinydb import TinyDB, where
from tinydb.storages import MemoryStorage


class MasterServer:
    def __init__(self) -> None:
        self.__db = TinyDB(storage=MemoryStorage)
        self.__servers = {
            'fitStage': FitnessLvlDataServer(self),
        }

    @property
    def fitnessStage(self) -> FitnessLvlDataServer:
        return self.__servers['fitStage']

    @property
    def db(self):
        '''Memory database that carries all program info while running.'''
        return self.__db
