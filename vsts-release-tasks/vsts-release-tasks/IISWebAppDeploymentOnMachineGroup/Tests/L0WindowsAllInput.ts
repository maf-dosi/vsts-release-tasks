import ma = require('vsts-task-lib/mock-answer');
import tmrm = require('vsts-task-lib/mock-run');
import path = require('path');

let taskPath = path.join(__dirname, '..', 'deployiiswebapp.js');
let tr: tmrm.TaskMockRunner = new tmrm.TaskMockRunner(taskPath);

tr.setInput('WebSiteName', 'mytestwebsite');
tr.setInput('Package', 'webAppPkg.zip');
tr.setInput('RemoveAdditionalFilesFlag', 'true');
tr.setInput('ExcludeFilesFromAppDataFlag', 'true');
tr.setInput('TakeAppOfflineFlag', 'false');
tr.setInput('VirtualApplication', 'mytestapp');
tr.setInput('AdditionalArguments', 'additionalArguments');
tr.setInput('WebAppUri', 'someuri');

process.env["SYSTEM_DEFAULTWORKINGDIRECTORY"] =  "DefaultWorkingDirectory";

// provide answers for task mock
let a: ma.TaskLibAnswers = <ma.TaskLibAnswers>{
    "which": {
        "msdeploy": "msdeploy"
    },
    "stats": {
    	"webAppPkg.zip": {
    		"isFile": true
    	}
    },
    "osType": {
        "osType": "Windows"
    },
    "checkPath": {
        "msdeploy": true
    },
    "exec": {
        "msdeploy -verb:sync -source:package='webAppPkg.zip' -dest:auto -setParam:name='IIS Web Application Name',value='mytestwebsite/mytestapp' -skip:Directory=App_Data additionalArguments": {
            "code": 0,
            "stdout": "Executed Successfully"
        },
        "msdeploy -verb:getParameters -source:package=\'webAppPkg.zip\'": {
            "code": 0,
            "stdout": "Executed Successfully"
        }
    },
    "exist": {
    	"webAppPkg.zip": true
    },
	
    "glob": {
        "webAppPkg.zip": ["webAppPkg.zip"],
    }
}

import mockTask = require('vsts-task-lib/mock-task');
var msDeployUtility = require('webdeployment-common/msdeployutility.js');

tr.registerMock('./msdeployutility.js', {
    getMSDeployCmdArgs : msDeployUtility.getMSDeployCmdArgs,
    getMSDeployFullPath : function() {
        var msDeployFullPath =  "msdeploypath\\msdeploy.exe";
        return msDeployFullPath;
    },
    containsParamFile: function(webAppPackage: string) {
        var taskResult = mockTask.execSync("msdeploy", "-verb:getParameters -source:package=\'" + webAppPackage + "\'");
        return true;
    }
});
var fs = require('fs');
tr.registerMock('fs', {
    createWriteStream: function(filePath, options){
        return {"isWriteableObj": true};
    },
    openSync: function(fd, options) {
        return true;
    },
    closeSync: function(fd) {
        return true;
    },
    fsyncSync: function(fd) {
        return true;
    }
});
tr.setAnswers(a);
tr.run();