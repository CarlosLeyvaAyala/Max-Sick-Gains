# Links a Listview with many controllers, so info is filled
# to this controllers when user clicks the Listview.
# This makes the Listview a navigator of sorts.

from PyQt5 import QtGui
from nutsbolts.DataServer import DataServer
from gui.mainWindow import Ui_MainWindow
from abc import ABC, abstractmethod
from PyQt5.QtWidgets import QComboBox, QLineEdit, QListView, QPlainTextEdit


class ListNav(ABC):
    def __init__(self, owner, dataServer: DataServer, ui: Ui_MainWindow, nav: QListView) -> None:
        self._server = dataServer
        self._ui = ui
        self._nav = nav
        self._owner = owner
        self._nav.setModel(dataServer.model)
        self._nav.clicked.connect(self.OnNavItemChange)
        self._nav.activated.connect(self.OnNavItemChange)  # On press enter
        # self._nav.pressed.connect(lambda: print("self.data")) # seems redundant with clicked
        self._AssociateCallbacks()
        self.NavToIndex(0)

    @abstractmethod
    def _AssociateCallbacks(self):
        pass

    def OnNavItemChange(self, item=None):
        """`<item>` may be None when changed programmatically.
        Otherwise, it's the object sent by clicking."""
        self._server.itemIndex = item.row() if item != None else self._server.itemIndex

    def NewRecordData(self):
        '''Adds a new record.'''
        self._server.NewData()
        self.NavToIndex(self.__LastRowIdx())

    def NavToIndex(self, idx: int):
        '''Navigates to some item index.'''
        self._server.itemIndex = idx
        item = self._server.model.index(self._server.itemIndex, 0)
        self._nav.setCurrentIndex(item)
        self.OnNavItemChange(None)

    def __LastRowIdx(self) -> int:
        '''Gets the index of the last record.'''
        return self._server.model.rowCount() - 1

    def _OnComboEdited(self, cb: QComboBox, key: str):
        '''Callback to edit a value when a combobox has changed.'''
        cb.currentIndexChanged.connect(
            lambda: self._server.EditData(key, cb.currentIndex())
        )

    def _OnComboNav(self, cb: QComboBox, key: str):
        '''Callback to set the value of a ComboBox when clicked on nav control.'''
        cb.setCurrentIndex(self._server.GetData(key))

    def _OnLineEdited(self, edt: QLineEdit, key: str):
        '''Callback to edit a value when a LineEdit has changed.'''
        edt.editingFinished.connect(
            lambda: self._server.EditData(key, edt.text())
        )

    def _OnLineNav(self, edt: QLineEdit, key: str):
        '''Callback to set the value of a LineEdit when clicked on the nav control.'''
        edt.setText(self._server.GetData(key))

    def _OnMemoEdited(self, mmo: QPlainTextEdit, key: str):
        mmo.textChanged.connect(
            lambda: self._server.EditData(
                key,
                mmo.toPlainText().split('\n')
            )
        )
