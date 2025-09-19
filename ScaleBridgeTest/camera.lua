--FoxCamera Configs
FOXCamera = require("FOXCamera")
local MyCamera = FOXCamera.newCamera(models.model.root.Head.EyePos) --can be localized now
MyCamera.doEyeOffset = true
MyCamera.distance = 5
FOXCamera.setCamera(MyCamera)

