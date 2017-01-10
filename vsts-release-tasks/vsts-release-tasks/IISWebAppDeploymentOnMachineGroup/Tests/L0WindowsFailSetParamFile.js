"use strict";
const tmrm = require('vsts-task-lib/mock-run');
const path = require('path');
let taskPath = path.join(__dirname, '..', 'deployiiswebapp.js');
let tr = new tmrm.TaskMockRunner(taskPath);
tr.setInput('WebSiteName', 'mytestwebsite');
tr.setInput('Package', 'webAppPkg.zip');
tr.setInput('SetParametersFile', 'invalidparameterFile.xml');
process.env["SYSTEM_DEFAULTWORKINGDIRECTORY"] = "DefaultWorkingDirectory";
let a = {
    "stats": {
        "webAppPkg.zip": {
            "isFile": true
        },
        "invalidparameterFile.xml": {
            "isFile": false
        }
    },
    "exist": {
        "webAppPkg.zip": true
    }
};
var msDeployUtility = require('webdeployment-common/msdeployutility.js');
tr.setAnswers(a);
tr.run();
