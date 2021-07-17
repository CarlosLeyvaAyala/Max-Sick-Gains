dim app
set app = CreateObject("Photoshop.Application")
dim doc
set doc = app.ActiveDocument
doc.Layers(1).name = "Layer 2"
doc.Layers(2).name = "Layer 1"
