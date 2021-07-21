from PyQt5 import QtWidgets, QtCore
from PyQt5.QtGui import QStandardItem, QStandardItemModel
from PyQt5.QtWidgets import QAbstractSlider, QFileDialog, QLineEdit, QSlider
from nutsbolts.DataServer.FitnessLvlDataServer import FitnessLvlDataServer
from qtrangeslider import QLabeledRangeSlider, QRangeSlider
# from nutsbolts import DataServer

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
        self.__fitLvlSrvr = FitnessLvlDataServer()
        app = QtWidgets.QApplication(sys.argv)
        self.initWidgets()
        self.update_widgets()
        self.widgetActions()
        self.newDoc()
        self.connectListViews()

        self.MainWindow.show()
        sys.exit(app.exec_())

    def initWidgets(self):
        self.MainWindow = QtWidgets.QMainWindow()
        self.ui = Ui_MainWindow()
        self.ui.setupUi(self.MainWindow)

        # https://pypi.org/project/QtRangeSlider/
        # https://www.tutorialspoint.com/pyqt/pyqt_qslider_widget_signal.htm
        self.initWeightSl(1)
        self.initMuscleSl()
        self.initBlendSl()

        self.gradient = Gradient()
        self.ui.verticalLayout_PlayerStages.addWidget(self.gradient)
        # self.MainWindow.setCentralWidget(self.gradient)

    def initWeightSl(self, pos):
        self.slBsWeight = QLabeledRangeSlider(QtCore.Qt.Orientation.Horizontal)
        self.slBsWeight.setHandleLabelPosition(
            QLabeledRangeSlider.LabelPosition.LabelsBelow)
        self.slBsWeight.setMaximum(100)
        self.slBsWeight.setTickInterval(10)
        self.slBsWeight.setValue([0, 100])
        self.slBsWeight.setTickPosition(QSlider.TicksBothSides)
        self.slBsWeight.setToolTip(
            'Click on this control, then press Shift + F1 for detailed info on it')
        self.ui.formLayout_3.addWidget(self.slBsWeight)
        self.ui.formLayout_3.setWidget(
            pos, QtWidgets.QFormLayout.FieldRole, self.slBsWeight)

    def initMuscleSl(self):
        self.slBsMuscle = QLabeledRangeSlider(QtCore.Qt.Orientation.Horizontal)
        self.slBsMuscle.setHandleLabelPosition(
            QLabeledRangeSlider.LabelPosition.LabelsBelow)
        self.slBsMuscle.setMinimum(1)
        self.slBsMuscle.setMaximum(6)
        self.slBsMuscle.setValue([1, 6])
        self.slBsMuscle.setTickPosition(QSlider.TicksBothSides)
        self.slBsMuscle.setToolTip(
            'Click on this control, then press Shift + F1 for detailed info on it')
        self.ui.formLayout_3.addWidget(self.slBsMuscle)
        self.ui.formLayout_3.setWidget(
            3, QtWidgets.QFormLayout.FieldRole, self.slBsMuscle)

    def initBlendSl(self):
        self.slBsBlend = QLabeledRangeSlider(QtCore.Qt.Orientation.Horizontal)
        self.slBsBlend.setHandleLabelPosition(
            QLabeledRangeSlider.LabelPosition.LabelsBelow)
        self.slBsBlend.setMinimum(5)
        self.slBsBlend.setMaximum(30)
        self.slBsBlend.setValue([20])
        self.slBsBlend.setTickPosition(QSlider.TicksBothSides)
        self.slBsBlend.setTickInterval(5)
        self.slBsBlend.setPageStep(10)
        self.slBsBlend.setToolTip(
            'Click on this control, then press Shift + F1 for detailed info on it')
        self.ui.formLayout_3.addWidget(self.slBsBlend)
        self.ui.formLayout_3.setWidget(
            4, QtWidgets.QFormLayout.FieldRole, self.slBsBlend)

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
        self.fitStagesModel = self.__fitLvlSrvr.model

        self.ui.LV_FitStages_nav.setModel(self.fitStagesModel)
        self.fitStagesModel.itemChanged.connect(
            lambda item: print(item.text()))
        self.ui.cbNPC_ClassFitness.setModel(self.fitStagesModel)
        self.ui.LV_FitStages_nav.clicked.connect(self.nav)
        self.ui.LV_FitStages_nav.activated.connect(self.nav)
        self.ui.LV_FitStages_nav.pressed.connect(lambda: print(self.data))
        self.ui.ed_FitStages_name.editingFinished.connect(
            lambda: self.fitStagesModel.item(self.itemIndex).setText(self.ui.ed_FitStages_name.text()))
        self.ui.btn_FitStages_femBs.clicked.connect(
            lambda: self.setFitStageBs(self.ui.ed_FitStages_femBs))

    def setFitStageBs(self, edit: QLineEdit):
        options = QFileDialog.Options()
        fileName, _ = QFileDialog.getOpenFileName(
            self.MainWindow, "Select a Bodyslide preset", "", "Bodyslide preset (*.xml)", options=options)
        edit.setText(fileName)
        # self.ui.btn_FitStages_FBs.pressed.connect(lambda: print('press'))

    def nav(self, idx):
        self.itemIndex = idx.row()
        print(self.itemIndex, idx.data())

    def newDoc(self):
        return


if __name__ == "__main__":
    Maxick()
