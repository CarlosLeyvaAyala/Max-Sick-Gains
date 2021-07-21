from nutsbolts.DataServer import DataServer


class FitnessLvlDataServer(DataServer.DataServer):
    def __init__(self) -> None:
        super().__init__()

    def ReadFromFile(self, fileName):
        self.NewFile()

    def _NewFileData(self):
        return [
            {
                'type': 'fitStage',
                'id': 1,
                'name': 'Default',
                'femBs': '',
                'manBs': '',
                'excludedRaces': ['Child'],
            }
        ]
