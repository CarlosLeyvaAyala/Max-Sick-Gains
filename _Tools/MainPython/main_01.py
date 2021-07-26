from PyQt5 import QtWidgets, QtCore
from PyQt5.QtGui import QStandardItem, QStandardItemModel
from PyQt5.QtWidgets import QSlider, QDesktopWidget
from nutsbolts.GUIController.FitStagesNavCtrl import FitStagesNav
from qtrangeslider import QLabeledRangeSlider, QRangeSlider
from nutsbolts.DataServer.MasterServer import *

from gui.mainWindow import Ui_MainWindow
from gui.gradient import Gradient
import sys

QtWidgets.QApplication.setAttribute(
    QtCore.Qt.AA_EnableHighDpiScaling, True)  # enable highdpi scaling
QtWidgets.QApplication.setAttribute(
    QtCore.Qt.AA_UseHighDpiPixmaps, True)  # use highdpi icons


class Maxick():
    def __init__(self) -> None:
        self.data = []
        self.__masterServer = MasterServer()
        app = QtWidgets.QApplication(sys.argv)
        self.initWidgets()
        self.update_widgets()
        self.widgetActions()
        self.newDoc()
        self.connectListViews()
        self.__fitStagesNav = FitStagesNav(
            self, self.__masterServer.fitnessStage, self.ui, self.ui.lv_FitStages_nav)

        self.MainWindow.show()
        self.CenterWindow()
        sys.exit(app.exec_())

    def CenterWindow(self):
        qtRectangle = self.MainWindow.frameGeometry()
        centerPoint = QDesktopWidget().availableGeometry().center()
        qtRectangle.moveCenter(centerPoint)
        self.MainWindow.move(qtRectangle.topLeft())

    def initWidgets(self):
        self.MainWindow = QtWidgets.QMainWindow()
        self.ui = Ui_MainWindow()
        self.ui.setupUi(self.MainWindow)

        # Can't create in Designer. Had to create them by code.

        # https://pypi.org/project/QtRangeSlider/
        # https://www.tutorialspoint.com/pyqt/pyqt_qslider_widget_signal.htm
        self.__InitWeightSl(1)
        self.__InitMuscleSl(3)
        self.__InitBlendSl(4)

        self.gradient = Gradient()
        self.ui.verticalLayout_PlayerStages.addWidget(self.gradient)

        # Models
        self.__fitTypesModel = QStandardItemModel(None)
        self.FillCombobox(self.ui.cb_FitStages_muscleType,
                          self.__fitTypesModel, ['Plain', 'Athletic', 'Fat'])
        self.__fitStageRippedLvlModel = QStandardItemModel(None)
        self.FillCombobox(self.ui.cb_FitStages_muscleLvl,
                          self.__fitStageRippedLvlModel,
                          ['Allow all', '1', '2', '3', '4', '5', '6'])

    def FillCombobox(self, cb, model, items):
        for val in items:
            item = QStandardItem(val)
            model.appendRow(item)
        cb.setModel(model)

    def __NewRangeSlider(self, min, max, interval, val):
        sl = QLabeledRangeSlider(QtCore.Qt.Orientation.Horizontal)
        sl.setHandleLabelPosition(
            QLabeledRangeSlider.LabelPosition.LabelsBelow)
        sl.setEdgeLabelMode(QLabeledRangeSlider.EdgeLabelMode.NoLabel)
        sl.setMinimum(min)
        sl.setMaximum(max)
        sl.setTickInterval(interval)
        sl.setValue(val)
        sl.setTickPosition(QSlider.TicksBothSides)
        sl.setToolTip(
            'Click on this control, then press Shift + F1 for detailed info on it')
        return sl

    def __SetFieldCtrlPos(self, pos: int, lyt, ctrl):
        '''Sets a control as `Field` in a `Form Layout`.'''
        lyt.addWidget(ctrl)
        lyt.setWidget(pos, QtWidgets.QFormLayout.FieldRole, ctrl)

    def __InitWeightSl(self, pos):
        self.slBsWeight = self.__NewRangeSlider(0, 100, 10, [0, 100])
        self.__SetFieldCtrlPos(pos, self.ui.formLayout_3, self.slBsWeight)

    def __InitMuscleSl(self, pos):
        self.slBsMuscle = self.__NewRangeSlider(1, 6, 1, [1, 6])
        self.__SetFieldCtrlPos(pos, self.ui.formLayout_3, self.slBsMuscle)

    def __InitBlendSl(self, pos):
        self.slBsBlend = self.__NewRangeSlider(5, 30, 5, [20])
        self.__SetFieldCtrlPos(pos, self.ui.formLayout_3, self.slBsBlend)

    def widgetActions(self):
        self.ui.actionExit.triggered.connect(lambda: self.MainWindow.close())

    def update_widgets(self):
        self.gradient.setStatusTip(
            "Visual representation of the player's current Fitness stages")
        self.gradient.setToolTip(
            'Orange = Fitness stage. Teal = blending beetween stages.')
        self.gradient.setWhatsThis('<html><head/><body><p>This will help you better visualize all the Fitness stages your Player Character will go through.</p><p><img src=":/img/fitness-journey.png"/></p><p><br/><span style=" font-weight:600;">Fitness stages</span> are represented in <span style=" font-weight:600; color:#ff7f50;">Orange</span>.<br/><span style=" font-weight:600;">Blending</span> of Bodyslide presets between stages are <span style=" font-weight:600; color:#008080;">Teal</span>.<br/>The exact points of <span style=" font-weight:600;">changing stages and blending</span> are marked as <span style=" font-weight:600; color:#ffffff; background-color:#000000;">White lines</span>.</p></body></html>')

        self.gradient.setGradient(
            [(0.2, 'Coral'), (0.22, 'Teal'), (0.26, 'Coral'), (0.36, 'Coral'), (0.4, 'Teal'), (0.43, 'Coral')])
        # Send all widgets to top
        self.ui.horizontalLayout_muscleDefActivate.addStretch()
        self.ui.verticalLayout_PlayerStages.addStretch()

    def connectListViews(self):
        return
        # self.fitStagesModel = self.__fitStagesSrvr.model
        # self.ui.cbNPC_ClassFitness.setModel(self.fitStagesModel)

        # self.fitStagesModel.itemChanged.connect(
        #     lambda item: print(item.text()))

    def newDoc(self):
        return


if __name__ == "__main__":
    Maxick()
