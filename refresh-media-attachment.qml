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
    property variant ignoringTag;

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
        ignoringTag = {beginning:"<!-- ignoreSection -->",ending:"<!-- \\ignoreSection -->"};
        refreshFoldersActionId = "refreshMediaAttachmentFolder";
        mediaPaths = [""].concat(mediaFolderPaths.split(pathSeparator));
        attachmentPaths =  [""].concat(attachmentFolderPaths.split(pathSeparator));
        script.registerCustomAction(refreshFoldersActionId, "Refresh folders: attachments", "Refresh folders: attachments", "", true);
    }

    function customActionInvoked(action) {
        if (action === refreshFoldersActionId) {
            //Current Note
            let curNote = script.currentNote();
            let curNoteContent = curNote.noteText

            //Select media folder path
            let mediaFolder = script.inputDialogGetItem("Seleccione carpeta multimedia","Seleccione la carpeta multimedia por la que se desean actualizar las rutas.",mediaPaths);
            if(mediaFolder === "") return false;
            if (!checkPathEnding(mediaFolder,mediaFolderName)){
                script.informationMessageBox("La ultima carpeta de la ruta " + mediaFolder + " debe ser: " + mediaFolderName, "Error");
                return false;
            }

            //Select media folder path
            let attachmentFolder = script.inputDialogGetItem("Seleccione carpeta de adjuntos","Seleccione la carpeta de adjuntos por la que se desean actualizar las rutas.",attachmentPaths);
            if(attachmentFolder === "") return false;
            if (!checkPathEnding(attachmentFolder,attachmentFolderName)){
                script.informationMessageBox("La ultima carpeta de la ruta " + attachmentFolder + " debe ser: " + attachmentFolderName, "Error");
                return false;
            }

            //Update media
            curNoteContent = updateMediaFolder(curNoteContent,mediaFolder);
            if(curNoteContent === null) return false;

            //Update file
            curNoteContent = updateFileFolder(curNoteContent,attachmentFolder);
            if(curNoteContent === null) return false;

            //Update note content
            script.noteTextEditSelectAll();
            script.noteTextEditWrite(curNoteContent);
            return true;
        }
    }

    function updateMediaFolder(pNoteContent,pNewPath){
        const mediaLineRegex = /(?:\!\[[^\r\n\]]+\]\([^\r\n\)]+\))|(?:\<img[^\>]*(?:\s|\"|\n)src\s*\=\s*\"[^\"]*\"[^\>]*\/\>)/g;
        const mediaLineFilter = (content, match)=>{return !isInsideIgnoreSection(content,match.index)};
        const mediaLines = extractMatches(pNoteContent,mediaLineRegex,mediaLineFilter);
        let newNoteContent = pNoteContent;

        for (const mediaLine of mediaLines){
            const mediaSrc = resolveAttachmentSrc(mediaLine.line);
            if (mediaSrc === null) return null;

            const subpathToReplace = getSubpathToReplace(mediaSrc, mediaFolderName);
            if (subpathToReplace === null) {
                script.informationMessageBox("La línea de multimedia '" + mediaLine.line.slice(1) + "' no presenta una ruta con la carpeta '" + mediaFolderName + "'.", "Error");
                return null;
            }

            const newMediaSrc = mediaSrc.replace(subpathToReplace, pNewPath);
            const newMediaLine = mediaLine.line.replace(mediaSrc,newMediaSrc);
            newNoteContent = newNoteContent.replace(mediaLine.line,newMediaLine);
        }

        return newNoteContent;
    }

    function updateFileFolder(pNoteContent,pNewPath){
        const fileLineRegex = /(?:\!?\[[^\r\n\]]+\]\([^\r\n\)]+\))|(?:\<a[^\>]*(?:\s|\"|\n)href\s*\=\s*\"[^\"]*\"[^\>]*\>)/g;
        const mediaFromMDCheckRegex = /^\!/;
        const fileLineFilter = (content, match)=>{return !(isInsideIgnoreSection(content,match.index) || mediaFromMDCheckRegex.test(match))};
        const fileLines = extractMatches(pNoteContent,fileLineRegex,fileLineFilter);
        let newNoteContent = pNoteContent;

        for (const fileLine of fileLines){
            const fileSrc = resolveAttachmentSrc(fileLine.line);
            if (fileSrc === null) return null;

            const subpathToReplace = getSubpathToReplace(fileSrc, attachmentFolderName);
            if (subpathToReplace === null) {
                script.informationMessageBox("La línea de archivo '" + fileLine.line.slice(1) + "' no presenta una ruta con la carpeta '" + attachmentFolderName + "'.", "Error");
                return null;
            }

            const newFileSrc = fileSrc.replace(subpathToReplace, pNewPath);
            const newFileLine = fileLine.line.replace(fileSrc,newFileSrc);
            newNoteContent = newNoteContent.replace(fileLine.line,newFileLine);
        }

        return newNoteContent;
    }

    function extractMatches(pContent, pRegex, pMatchFilter) {
        const matches = [];
        let match;

        while ((match = pRegex.exec(pContent)) !== null) {
            if (pMatchFilter(pContent, match)) {
                matches.push({ line: match[0], index: match.index });
            }
        }

        return matches;
    }

    function getSubpathToReplace(pPath, pSeekedFolderName) {
        const escapedSeparator = escapeRegExp(separator);
        const pattern = "^.*?" + escapedSeparator + pSeekedFolderName + "(?=(" + escapedSeparator + "|$))";
        const regex = new RegExp(pattern, "");
        const match = pPath.match(regex);
        return match ? match[0] : null;
    }

    function resolveAttachmentSrc(pSubstring) {
        const pathFromMD = getMDAttachmentSrc(pSubstring);
        const pathFromHTML = getHTMLAttachmentTagSrc(pSubstring);

        if (pathFromMD !== null && pathFromHTML === null) {
            return pathFromMD;
        } else if (pathFromMD === null && pathFromHTML !== null) {
            return pathFromHTML;
        } else {
            script.informationMessageBox("La línea '" + pSubstring.slice(1) + "' presenta ambigüedad en su recurso de origen.", "Error");
            return null;
        }
    }

    function getMDAttachmentSrc(pString){
        let pathContainerRegex = /\([^\r\n\)]+\)/;
        let result = pString.match(pathContainerRegex);
        if(result!==null){
            return result[0].slice(1,-1);
        }
        else
            return null;
    }

    function getHTMLAttachmentTagSrc(pString){
        let pathContainerRegex = /(\s|\")(href|src)\s*\=\s*\"[^\"]*\"/;
        let result = pString.match(pathContainerRegex);
        if(result!==null){
            let pathRegex = /\"[^\"]*\"(?=$)/;
            result = result[0].match(pathRegex);
            return result[0].slice(1,-1);
        }
        else
            return null;
    }

    function isInsideIgnoreSection(pContent, pPosition) {
        const startTag = "<!-- ignoreSection -->";
        const endTag = "<!-- \\ignoreSection -->";

        let lastStart = pContent.lastIndexOf(startTag, pPosition);
        let lastEnd = pContent.lastIndexOf(endTag, pPosition);

        return lastStart !== -1 && (lastEnd === -1 || lastStart > lastEnd);
    }

    function lastIndexOfRegex(pContent, pRegex, pBeginnigIndex = 0, pEndingNumber = pContent.length){
        const selectedContent = pContent.slice(pBeginnigIndex, pEndingNumber);
        //TODO: https://stackoverflow.com/questions/5835469/changing-the-regexp-flags
    }

    function checkPathEnding(pPath, pExpectedValue){
        let pPathArray = pPath.split(separator);
        return pPathArray[pPathArray.length - 1] === pExpectedValue;
    }

    function checkPathBeginnig(pPath, pExpectedValue){
        let pPathArray = pPath.split(separator);
        return pPathArray[0] === pExpectedValue;
    }

    function escapeRegExp(str) {
        return str.replace(/[.*+?^${}()|[\]\\/]/g, '\\$&');
    }
}
