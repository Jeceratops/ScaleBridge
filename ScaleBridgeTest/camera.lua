--FoxCamera Configs
FOXCamera = require("FOXCamera")
MyCamera = FOXCamera.newCamera(models.model.root.Head.EyePos)
MyCamera.doEyeOffset = true
MyCamera.distance = 5
FOXCamera.setCamera(MyCamera)
