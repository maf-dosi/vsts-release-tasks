"use strict";
const tmrm = require('vsts-task-lib/mock-run');
const path = require('path');
let taskPath = path.join(__dirname, '..', 'deployiiswebapp.js');
let tr = new tmrm.TaskMockRunner(taskPath);
tr.setInput('WebSiteName', 'mytestwebsite');
tr.setInput('Package', 'Invalid_webAppPkg');
process.env["SYSTEM_DEFAULTWORKINGDIRECTORY"] = "DefaultWorkingDirectory";
// provide answers for task mock
let a = {
    "glob": {
        "Invalid_webAppPkg": [],
    }
};
tr.setAnswers(a);
tr.run();
