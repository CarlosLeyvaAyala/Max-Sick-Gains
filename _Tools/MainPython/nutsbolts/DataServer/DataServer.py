# DataServers are hubs were all information is stored, so info is
# decoupled from everything else.

from abc import ABC, abstractmethod
from PyQt5.QtGui import QStandardItem, QStandardItemModel
import pprint


class DataServer(ABC):
    recordType = ''  # Used for saving/loading info. Each descendant needs to override this

    def __init__(self, master) -> None:
        self._model = QStandardItemModel(None)
        self.__data = []
        self.NewFile()
        self._masterServer = master

    @property
    def model(self) -> QStandardItemModel:
        return self._model

    @property
    def itemIndex(self) -> int:
        return self.__itemIndex

    @itemIndex.setter
    def itemIndex(self, idx: int):
        self.__itemIndex = idx if idx >= 0 else 0

    def NewFile(self):
        self.__itemIndex = 0
        print(self._masterServer)
        # self._masterServer.db.insert(self._NewFileData())
        # print(self._masterServer.db.all())
        self.__data = [self._NewFileData()]
        self._FillModel()
        # print(self.__data)

    @abstractmethod
    def _NewFileData(self):
        pass

    @abstractmethod
    def _NewRecordData(self):
        pass

    def ReadFromFile(self, fileName):
        return

    def _FillModel(self):
        self._model.clear()
        for val in self.__data:
            item = QStandardItem(val.get('name', 'ERROR: no name defined'))
            self._model.appendRow(item)

    def GetData(self, key, index=None):
        idx = self.__itemIndex if index == None else index
        return self.__data[idx][key]

    def NewData(self):
        self.__data.append(self._NewRecordData())
        # pprint.pprint(self.__data)
        self._FillModel()

    def EditData(self, key, value, index=None):
        idx = self.__itemIndex if index == None else index
        self.__data[idx][key] = value
        if key == 'name':
            self._model.item(idx).setText(value)
