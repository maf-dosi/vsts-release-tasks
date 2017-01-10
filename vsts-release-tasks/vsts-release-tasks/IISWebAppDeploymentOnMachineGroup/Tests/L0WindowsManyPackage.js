"use strict";
const tmrm = require('vsts-task-lib/mock-run');
const path = require('path');
let taskPath = path.join(__dirname, '..', 'deployiiswebapp.js');
let tr = new tmrm.TaskMockRunner(taskPath);
tr.setInput('WebSiteName', 'mytestwebsite');
tr.setInput('Package', 'webAppPkgPattern/**/*.zip');
process.env["SYSTEM_DEFAULTWORKINGDIRECTORY"] = "DefaultWorkingDirectory";
// provide answers for task mock
let a = {
    "stats": {
        "webAppPkg.zip": {
            "isFile": true
        }
    },
    "checkPath": {
        "cmd": true,
        "webAppPkgPattern": true
    },
    "exist": {
        "webAppPkg.zip": true,
        "webAppPkg": true
    },
    "find": {
        "webAppPkgPattern/": ["webAppPkgPattern/webAppPkg1.zip", "webAppPkgPattern/webAppPkg2.zip"]
    }
};
tr.setAnswers(a);
tr.run();
