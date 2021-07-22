from nutsbolts.GUIController.ListNavController import ListNav

from PyQt5.QtWidgets import QComboBox, QListView, QFileDialog, QLineEdit
from nutsbolts.DataServer import DataServer
from gui.mainWindow import Ui_MainWindow
import os


class FitStagesNav(ListNav):
    def __init__(self, owner, dataServer: DataServer, ui: Ui_MainWindow, nav: QListView) -> None:
        super().__init__(owner, dataServer, ui, nav)

    # Having direct access to ui controls is not a beautiful solution, but it's a practical one
    def OnNavItemChange(self, item):
        super().OnNavItemChange(item)

        # Can't delete default stage
        if self._server.itemIndex == 0:
            self._ui.actionDeleteStage.setDisabled(True)
        else:
            self._ui.actionDeleteStage.setEnabled(True)

        # Get data on item change
        self._OnLineNav(self._ui.ed_FitStages_name, 'name')
        self._OnLineNav(self._ui.ed_FitStages_displayName, 'displayName')
        self._OnLineNav(self._ui.ed_FitStages_femBs, 'femBs')
        self._OnLineNav(self._ui.ed_FitStages_femBsUrl, 'femBsUrl')
        self._OnLineNav(self._ui.ed_FitStages_manBs, 'manBs')
        self._OnLineNav(self._ui.ed_FitStages_manBsUrl, 'manBsUrl')
        self._OnComboNav(self._ui.cb_FitStages_muscleType, 'muscleDefType')
        self._OnComboNav(self._ui.cb_FitStages_muscleLvl, 'muscleDef')
        self._ui.mmo_FitStages_racesExcl.setPlainText(
            '\n'.join(self._server.GetData('excludedRaces')))

    def _AssociateCallbacks(self):
        self.__ControlsOnEdit()
        # Bodyslide buttons
        self.__BsBtn(self._ui.btn_FitStages_femBs,
                     self._ui.ed_FitStages_femBs, 'femBs')
        self.__BsBtn(self._ui.btn_FitStages_manBs,
                     self._ui.ed_FitStages_manBs, 'manBs')
        self.__CreateNavContextMenu()

    def __BsBtn(self, btn, edt, key: str):
        """Asociates some button to a open Bodyslide dialog and it's line edit."""
        btn.clicked.connect(lambda: self.setFitStageBs(key, edt))

    def __ControlsOnEdit(self):
        '''Values updated when controls change'''
        self._OnLineEdited(self._ui.ed_FitStages_name, 'name')
        self._OnLineEdited(self._ui.ed_FitStages_displayName, 'displayName')
        self._OnLineEdited(self._ui.ed_FitStages_femBs, 'femBs')
        self._OnLineEdited(self._ui.ed_FitStages_femBsUrl, 'femBsUrl')
        self._OnLineEdited(self._ui.ed_FitStages_manBs, 'manBs')
        self._OnLineEdited(self._ui.ed_FitStages_manBsUrl, 'manBsUrl')
        # Combo boxes
        self._OnComboEdited(self._ui.cb_FitStages_muscleType, 'muscleDefType')
        self._OnComboEdited(self._ui.cb_FitStages_muscleLvl, 'muscleDef')
        self._OnMemoEdited(self._ui.mmo_FitStages_racesExcl, 'excludedRaces')

    # Creates the context menu when right clicked the nav
    # https://wiki.python.org/moin/PyQt/Handling%20context%20menus
    def __CreateNavContextMenu(self):
        # New record
        self._ui.actionNewStage.triggered.connect(self.NewRecordData)
        self._ui.lv_FitStages_nav.addAction(self._ui.actionNewStage)
        # Delete record
        self._ui.actionDeleteStage.triggered.connect(lambda: print('Delete'))
        self._ui.lv_FitStages_nav.addAction(self._ui.actionDeleteStage)

    # Opens a dialog asking for a Bodyslide preset
    def setFitStageBs(self, key, edit: QLineEdit):
        fileName, _ = QFileDialog.getOpenFileName(
            None,
            'Select a Bodyslide preset',
            os.path.dirname(edit.text()),
            'Bodyslide preset (*.xml)',
            options=QFileDialog.Options()
        )
        if fileName != '':
            edit.setText(fileName)
            self._server.EditData(key, fileName)
