import QtQml 2.2
import QOwnNotesTypes 1.0
import com.qownnotes.noteapi 1.0

Script {

    property string separator;
    property string pathSeparator;
    property string mediaFolderName;
    property string attachmentFolderName;
    property string mediaFolderPaths;
    property string attachmentFolderPaths;

    property variant settingsVariables: [
        {
            "identifier": "separator",
            "name": "Separador de carpetas",
            "description": "",
            "type": "string",
            "default": "/",
        },
        {
            "identifier": "pathSeparator",
            "name": "Separador de rutas",
            "description": "",
            "type": "string",
            "default": ";",
        },
        {
            "identifier": "mediaFolderName",
            "name": "Nombre de la carpeta de archivos multimedia",
            "description": "",
            "type": "string",
            "default": "media",
        },
        {
            "identifier": "attachmentFolderName",
            "name": "Nombre de la carpeta de archivos adjuntos",
            "description": "",
            "type": "string",
            "default": "attachment",
        },
        {
            "identifier": "mediaFolderPaths",
            "name": "Rutas de carpetas multimedia",
            "description": "",
            "type": "string"
        },
        {
            "identifier": "attachmentFolderPaths",
            "name": "Rutas de carpetas adjuntos",
            "description": "",
            "type": "string"
        }
    ];

    var refreshFoldersActionId = "refreshMediaAttachmentFolder";
    var mediaPaths;
    var attachmentPaths;

    function init() {
        script.registerCustomAction(refreshFoldersActionId, "refresh attachment folders", "refresh attachment folders", "", true);
        mediaPaths = mediaFolderPaths.split(pathSeparator);
        attachmentPaths =  attachmentFolderPaths(pathSeparator);
    }

    function askUserToSelectItemInArray(pTitle,pDescription,pArray){
        return script.inputDialogGetItem(pTitle, pDescription,pArray);
    }

    function checkPathEnding(pPath, pExpectedValue){
        var pPathArray = pPath.split(separator);
        return pPathArray[pPathArray.length - 1] == pExpectedValue;
    }

    function updateAttachmentFolder(pNewPath){
        // \!?(\[[^\r\n\]]+\]\([^\r\n\)]+\))|(\<a[^\>]*(\s|\")href\s*\=\s*\"[^\"]*\"\>)
        //TODO: HACERLO XD

    }

    function customActionInvoked(action) {
        if (action == refreshFoldersActionId) {
            //Current Note
            var curNote = script.currentNote();

            //Select media folder path
            var mediaFolder = askUserToSelectItemInArray("Seleccione carpeta multimedia","Seleccione la carpeta multimedia por la que se desean actualizar las rutas.",mediaPaths)
            if (!checkPathEnding(mediaFolder,mediaFolderName)){
                script.informationMessageBox("La ultima carpeta de la ruta " + mediaFolder + " debe ser: " + mediaFolderName, "Error");
                return false;
            }

            //Select media folder path
            var attachmentFolder = askUserToSelectItemInArray("Seleccione carpeta de adjuntos","Seleccione la carpeta de adjuntos por la que se desean actualizar las rutas.",attachmentPaths)
            if (!checkPathEnding(attachmentFolder,attachmentFolderName)){
                script.informationMessageBox("La ultima carpeta de la ruta " + attachmentFolder + " debe ser: " + attachmentFolderName, "Error");
                return false;
            }


        }
    }

    function getPathFromMD(pString){
        var pathContainerPattern = "\([^\r\n\)]+\)";
        var pathContainerRegex = RegExp(pathContainerPattern, "g");
        var result;
        if((result = pathContainerRegex.exec(pString))!=null){
            return result[0].slice(1,-1);
        }
        else
            return null;
    }

    function getPathFromHTML(pString){
        var pathContainerPattern = "(\s|\")(href|src)\s*\=\s*\"[^\"]*\"";
        var pathContainerRegex = RegExp(pathContainerPattern, "g");
        var result;
        if((result = pathContainerRegex.exec(pString))!=null){
            var pathPattern = "\"[^\"]\"";
            var pathRegex = RegExp(pathPattern,"g");
            result = pathRegex.exec(result);
            return result[0].slice(1,-1);
        }
        else
            return null;
    }
}
