from abc import ABC, abstractmethod
from PyQt5.QtGui import QStandardItem, QStandardItemModel


class DataServer(ABC):
    def __init__(self) -> None:
        self._model = QStandardItemModel(None)
        self._data = []
        self.NewFile()

    @property
    def model(self):
        return self._model

    @property
    def itemIndex(self):
        return self.__itemIndex

    @itemIndex.setter
    def itemIndex(self, idx):
        self.__itemIndex = idx

    def NewFile(self):
        self.__itemIndex = 0
        self._data = self._NewFileData()
        self._FillModel()
        print(self._data)

    @abstractmethod
    def _NewFileData(self):
        pass

    @abstractmethod
    def ReadFromFile(self, fileName):
        pass

    def _FillModel(self):
        self._model.clear()
        for val in self._data:
            item = QStandardItem(val.get('name', 'ERROR: no name defined'))
            self._model.appendRow(item)

    def GetData(self, key):
        return self._data[key]
