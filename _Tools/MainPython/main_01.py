from gui.gui_01 import Ui_MainWindow
from PyQt5 import QtWidgets
import sys


class TestGUI():
    def __init__(self) -> None:
        app = QtWidgets.QApplication(sys.argv)
        self.MainWindow = QtWidgets.QMainWindow()
        self.ui = Ui_MainWindow()
        self.ui.setupUi(self.MainWindow)
        self.update_widgets()
        self.widget_actions()
        self.MainWindow.show()
        sys.exit(app.exec_())

    def widget_actions(self):
        self.ui.actionExit.setStatusTip('eouirnuireoi')
        self.ui.actionExit.triggered.connect(self.close_GUI)
        self.ui.actionNew.setStatusTip('jurl asdf')

    def close_GUI(self):
        self.MainWindow.close()

    def update_widgets(self):
        self.MainWindow.setWindowTitle('PyQt5 GUI')


if __name__ == "__main__":
    TestGUI()
