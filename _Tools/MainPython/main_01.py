from gui.gui_01 import Ui_MainWindow
from PyQt5 import QtWidgets, QtCore
from gui.gradient import Gradient
import sys

QtWidgets.QApplication.setAttribute(
    QtCore.Qt.AA_EnableHighDpiScaling, True)  # enable highdpi scaling
QtWidgets.QApplication.setAttribute(
    QtCore.Qt.AA_UseHighDpiPixmaps, True)  # use highdpi icons


class TestGUI():
    def __init__(self) -> None:
        app = QtWidgets.QApplication(sys.argv)
        self.initWidgets()
        self.update_widgets()
        self.widget_actions()

        self.MainWindow.show()
        sys.exit(app.exec_())

    def initWidgets(self):
        self.MainWindow = QtWidgets.QMainWindow()
        self.ui = Ui_MainWindow()
        self.ui.setupUi(self.MainWindow)
        self.gradient = Gradient()
        self.ui.verticalLayout_PlayerStages.addWidget(self.gradient)
        self.gradient.setStatusTip(
            "Visual representation of the player's current Fitness stages")
        # self.MainWindow.setCentralWidget(self.gradient)

    def widget_actions(self):
        return
        # self.ui.actionExit.setStatusTip('eouirnuireoi')
        # self.ui.actionExit.triggered.connect(self.close_GUI)
        # self.ui.actionNew.setStatusTip('jurl asdf')

    def close_GUI(self):
        self.MainWindow.close()

    def update_widgets(self):
        self.gradient.setGradient(
            [(0.2, 'DarkOrange'), (0.22, 'Teal'), (0.26, 'DarkOrange'), (0.36, 'DarkOrange'), (0.4, 'Teal'), (0.43, '#ff6347')])
        # Send all widgets to top
        self.ui.verticalLayout_PlayerStages.addStretch()


if __name__ == "__main__":
    TestGUI()
