"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator.throw(value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments)).next());
    });
};
const tl = require('vsts-task-lib/task');
const path = require('path');
var msDeploy = require('webdeployment-common/deployusingmsdeploy.js');
var utility = require('webdeployment-common/utility.js');
function run() {
    return __awaiter(this, void 0, void 0, function* () {
        try {
            tl.setResourcePath(path.join(__dirname, 'task.json'));
            var webSiteName = tl.getInput('WebSiteName', true);
            var virtualApplication = tl.getInput('VirtualApplication', false);
            var webDeployPkg = tl.getPathInput('Package', true);
            var setParametersFile = tl.getPathInput('SetParametersFile', false);
            var removeAdditionalFilesFlag = tl.getBoolInput('RemoveAdditionalFilesFlag', false);
            var excludeFilesFromAppDataFlag = tl.getBoolInput('ExcludeFilesFromAppDataFlag', false);
            var takeAppOfflineFlag = tl.getBoolInput('TakeAppOfflineFlag', false);
            var additionalArguments = tl.getInput('AdditionalArguments', false);
            var availableWebPackages = utility.findfiles(webDeployPkg);
            if (availableWebPackages.length == 0) {
                throw new Error(tl.loc('Nopackagefoundwithspecifiedpattern'));
            }
            if (availableWebPackages.length > 1) {
                throw new Error(tl.loc('MorethanonepackagematchedwithspecifiedpatternPleaserestrainthesearchpatern'));
            }
            webDeployPkg = availableWebPackages[0];
            var isFolderBasedDeployment = yield utility.isInputPkgIsFolder(webDeployPkg);
            yield msDeploy.DeployUsingMSDeploy(webDeployPkg, webSiteName, null, removeAdditionalFilesFlag, excludeFilesFromAppDataFlag, takeAppOfflineFlag, virtualApplication, setParametersFile, additionalArguments, isFolderBasedDeployment, true);
        }
        catch (error) {
            tl.setResult(tl.TaskResult.Failed, error);
        }
    });
}
run();
