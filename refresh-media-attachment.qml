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

    property string refreshFoldersActionId;
    property variant mediaPaths;
    property variant attachmentPaths;

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
            "default": "attachments",
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

    function init() {
        refreshFoldersActionId = "refreshMediaAttachmentFolder";
        script.registerCustomAction(refreshFoldersActionId, "refresh attachment folders", "refresh attachment folders", "", true);
        mediaPaths = [""].concat(mediaFolderPaths.split(pathSeparator));
        attachmentPaths =  [""].concat(attachmentFolderPaths.split(pathSeparator));
    }

    function askUserToSelectItemInArray(pTitle,pDescription,pArray){
        return script.inputDialogGetItem(pTitle, pDescription,pArray);
    }

    function checkPathEnding(pPath, pExpectedValue){
        var pPathArray = pPath.split(separator);
        return pPathArray[pPathArray.length - 1] == pExpectedValue;
    }

    function checkPathBeginnig(pPath, pExpectedValue){
        var pPathArray = pPath.split(separator);
        return pPathArray[0] == pExpectedValue;
    }

    function updateMediaFolder(pNoteContent,pNewPath){
        var newNoteContent = pNoteContent;
        var imgLineRegex = /(?:\!\[[^\r\n\]]+\]\([^\r\n\)]+\))|(?:\<img[^\>]*(?:\s|\"|\n)src\s*\=\s*\"[^\"]*\"[^\>]*\/\>)/g;
        var escapedSeparator = escapeRegExp(separator);
        var imgFolderPathPattern = "^.*?"+ escapedSeparator + mediaFolderName + "(?=("+ escapedSeparator +"|$))";
        var imgFolderPathRegex = RegExp(imgFolderPathPattern, "");
        var imgLine;
        var pathFromMD = "";
        var pathFromHTML = "";
        var imgPath = "";
        var subPathToReplace = "";
        var newImgPath = "";
        var newImgLine;
        while((imgLine = imgLineRegex.exec(pNoteContent)) !== null){
            pathFromMD = getPathFromMD(imgLine[0]);
            pathFromHTML = getPathFromHTML(imgLine[0]);
            if(pathFromMD != null && pathFromHTML == null){
                imgPath = pathFromMD;
            }else if(pathFromMD == null && pathFromHTML != null){
                imgPath = pathFromHTML;
            }else{
                script.informationMessageBox("La línea de multimedia '" + imgLine[0].slice(1) + "' presenta ambigüedad en su ruta.", "Error");
                return null;
            }
            subPathToReplace = imgPath.match(imgFolderPathRegex);
            if(subPathToReplace == null){
                script.informationMessageBox("La línea de multimedia '" + imgLine[0].slice(1) + "' no presenta una ruta con la carpeta '" + mediaFolderName +"'.", "Error");
                return null;
            }
            newImgPath = imgPath.replace(subPathToReplace[0], pNewPath);
            newImgLine = imgLine[0].replace(imgPath,newImgPath);
            newNoteContent = newNoteContent.replace(imgLine[0],newImgLine);
        }
        return newNoteContent;
    }

    function updateAttachmentFolder(pNoteContent,pNewPath){
        var newNoteContent = pNoteContent;
        var attachmentLineRegex = /(?:\!?\[[^\r\n\]]+\]\([^\r\n\)]+\))|(?:\<a[^\>]*(?:\s|\"|\n)href\s*\=\s*\"[^\"]*\"[^\>]*\>)/g;
        var imgFromMDCheckRegex = /^\!/;
        var escapedSeparator = escapeRegExp(separator);
        var attachmentFolderPathPattern = "^.*?"+ escapedSeparator + attachmentFolderName + "(?=("+ escapedSeparator +"|$))";
        var attachmentFolderPathRegex = RegExp(attachmentFolderPathPattern, "");
        var attachmentLine;
        var pathFromMD = "";
        var pathFromHTML = "";
        var attachmentPath = "";
        var subPathToReplace = "";
        var newAttachmentPath = "";
        var newAttachmentLine;
        while((attachmentLine = attachmentLineRegex.exec(pNoteContent)) !== null){
            if(!imgFromMDCheckRegex.test(attachmentLine[0])){
                pathFromMD = getPathFromMD(attachmentLine[0]);
                pathFromHTML = getPathFromHTML(attachmentLine[0]);
                if(pathFromMD != null && pathFromHTML == null){
                    attachmentPath = pathFromMD;
                }else if(pathFromMD == null && pathFromHTML != null){
                    attachmentPath = pathFromHTML;
                }else{
                    script.informationMessageBox("La línea de archivo adjunto '" + attachmentLine[0].slice(1) + "' presenta ambigüedad en su ruta.", "Error");
                    return null;
                }
                subPathToReplace = attachmentPath.match(attachmentFolderPathRegex);
                if(subPathToReplace == null){
                    script.informationMessageBox("La línea de archivo adjunto '" + attachmentLine[0].slice(1) + "' no presenta una ruta con la carpeta '" + attachmentFolderName +"'.", "Error");
                    return null;
                }
                newAttachmentPath = attachmentPath.replace(subPathToReplace[0], pNewPath);
                newAttachmentLine = attachmentLine[0].replace(attachmentPath,newAttachmentPath);
                newNoteContent = newNoteContent.replace(attachmentLine[0],newAttachmentLine);
            }
        }
        return newNoteContent;
    }

    function customActionInvoked(action) {
        if (action == refreshFoldersActionId) {
            //Current Note
            var curNote = script.currentNote();
            var curNoteContent = curNote.noteText

            //Select media folder path
            var mediaFolder = askUserToSelectItemInArray("Seleccione carpeta multimedia","Seleccione la carpeta multimedia por la que se desean actualizar las rutas.",mediaPaths);
            if(mediaFolder == "") return false;
            if (!checkPathEnding(mediaFolder,mediaFolderName)){
                script.informationMessageBox("La ultima carpeta de la ruta " + mediaFolder + " debe ser: " + mediaFolderName, "Error");
                return false;
            }

            //Select media folder path
            var attachmentFolder = askUserToSelectItemInArray("Seleccione carpeta de adjuntos","Seleccione la carpeta de adjuntos por la que se desean actualizar las rutas.",attachmentPaths);
            if(attachmentFolder == "") return false;
            if (!checkPathEnding(attachmentFolder,attachmentFolderName)){
                script.informationMessageBox("La ultima carpeta de la ruta " + attachmentFolder + " debe ser: " + attachmentFolderName, "Error");
                return false;
            }

            //Update media
            curNoteContent = updateMediaFolder(curNoteContent,mediaFolder);
            if(curNoteContent === null) return false;

            //Update attachment
            curNoteContent = updateAttachmentFolder(curNoteContent,attachmentFolder);
            if(curNoteContent === null) return false;

            //Update note content
            script.noteTextEditSelectAll();
            script.noteTextEditWrite(curNoteContent);
            return true;
        }
    }

    function getPathFromMD(pString){
        var pathContainerRegex = /\([^\r\n\)]+\)/;
        var result = pString.match(pathContainerRegex);
        if(result!==null){
            return result[0].slice(1,-1);
        }
        else
            return null;
    }

    function getPathFromHTML(pString){
        var pathContainerRegex = /(\s|\")(href|src)\s*\=\s*\"[^\"]*\"/;
        var result = pString.match(pathContainerRegex);
        if(result!==null){
            var pathRegex = /\"[^\"]*\"(?=$)/;
            result = result[0].match(pathRegex);
            return result[0].slice(1,-1);
        }
        else
            return null;
    }

    function escapeRegExp(str) {
      return str.replace(/[.*+?^${}()|[\]\\/]/g, '\\$&');
    }
}
