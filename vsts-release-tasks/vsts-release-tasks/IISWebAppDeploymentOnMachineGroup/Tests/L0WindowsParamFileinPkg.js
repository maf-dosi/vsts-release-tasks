"use strict";
const tmrm = require('vsts-task-lib/mock-run');
const path = require('path');
let taskPath = path.join(__dirname, '..', 'deployiiswebapp.js');
let tr = new tmrm.TaskMockRunner(taskPath);
tr.setInput('WebSiteName', 'mytestwebsite');
tr.setInput('Package', 'webAppPkg.zip');
tr.setInput('SetParametersFile', 'parameterFilePresent.xml');
process.env["SYSTEM_DEFAULTWORKINGDIRECTORY"] = "DefaultWorkingDirectory";
let a = {
    "which": {
        "msdeploy": "msdeploy"
    },
    "stats": {
        "webAppPkg.zip": {
            "isFile": true
        },
        "parameterFilePresent.xml": {
            "isFile": true
        },
        "parameterFileUser.xml": {
            "isFile": true
        }
    },
    "checkPath": {
        "webAppPkg.zip": true,
        "msdeploy": true
    },
    "osType": {
        "osType": "Windows"
    },
    "rmRF": {
        "DefaultWorkingDirectory\\tempSetParameters.xml": {
            "success": true
        }
    },
    "exec": {
        "msdeploy -verb:sync -source:package='webAppPkg.zip' -dest:auto -setParam:name='IIS Web Application Name',value='mytestwebsite' -setParamFile=tempSetParameters.xml  -enableRule:DoNotDeleteRule": {
            "code": 0,
            "stdout": "Executed Successfully"
        },
        "msdeploy -verb:getParameters -source:package=\'webAppPkg.zip\'": {
            "code": 0,
            "stdout": "Executed Successfully"
        }
    },
    "exist": {
        "webAppPkg.zip": true,
        "DefaultWorkingDirectory\\tempSetParameters.xml": true
    },
    "glob": {
        "webAppPkg.zip": ["webAppPkg.zip"]
    }
};
const mockTask = require('vsts-task-lib/mock-task');
var msDeployUtility = require('webdeployment-common/msdeployutility.js');
tr.registerMock('./msdeployutility.js', {
    getMSDeployCmdArgs: msDeployUtility.getMSDeployCmdArgs,
    getMSDeployFullPath: function () {
        var msDeployFullPath = "msdeploypath\\msdeploy.exe";
        return msDeployFullPath;
    },
    containsParamFile: function (webAppPackage) {
        var taskResult = mockTask.execSync("msdeploy", "-verb:getParameters -source:package=\'" + webAppPackage + "\'");
        return true;
    }
});
var fs = require('fs');
tr.registerMock('fs', {
    createWriteStream: function (filePath, options) {
        return { "isWriteStreamObj": true };
    },
    readFileSync: function (msDeployErrorFilePath) {
        console.log("reading the error file");
        return "ERROR DEPLOYING WEBSITE";
    },
    openSync: function (fd, options) {
        return true;
    },
    closeSync: function (fd) {
        return true;
    },
    fsyncSync: function (fd) {
        return true;
    }
});
tr.setAnswers(a);
tr.run();
