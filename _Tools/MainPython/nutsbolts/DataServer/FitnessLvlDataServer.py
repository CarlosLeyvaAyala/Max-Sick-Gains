# Info about Fitness Stages

from nutsbolts.DataServer import DataServer


class FitnessLvlDataServer(DataServer.DataServer):
    recordType = 'fitStage'         # Used for saving/loading info.

    def __init__(self, master) -> None:
        super().__init__(master)

    def _NewFileData(self):
        return {
            'type': 'fitStage',
            'id': 1,
            'name': 'Default',
            'displayName': 'plain looking',
            # FIXME: Set to blank
            'femBs': 'F:/Skyrim SE/MO2/mods/DM Bodyslide presets/CalienteTools/BodySlide/SliderPresets/DM Amazons 3BA Nude.xml',
            'femBsUrl': '',
            'manBs': '',
            'manBsUrl': '',
            'muscleDefType': 0,         # 0 - Meh, 1 - Fit, 2 - Fat
            # 0 - All allowed, [1,6] - Muscle level
            'muscleDef': 0,
            'excludedRaces': [
                    'Child'
            ],
        }

    def _NewRecordData(self):
        return {
            'type': 'fitStage',         # Used for saving/loading info
            # FIXME: Set to max + 1
            'id': 234234,
            'name': 'New stage',
            'displayName': '',
            'femBs': '',
            'femBsUrl': '',
            'manBs': '',
            'manBsUrl': '',
            'muscleDefType': 0,         # 0 - Meh, 1 - Fit, 2 - Fat
            # 0 - All allowed, [1,6] - Muscle level
            'muscleDef': 0,
            'excludedRaces': [
                    'Child'
            ],
        }
