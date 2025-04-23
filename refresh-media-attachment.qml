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
    property variant tagsContainer;
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

    function TagContainer(){
        this.openingPattern = null;
        this.opening = null;

        this.closingPattern = null;
        this.closing = null;

        this.tagSeparatorPattern = null;
        this.tagSeparator = null;

        this.tagOpeningPrefixPattern = null;
        this.tagOpeningPrefix = null;

        this.tagClosingPrefixPattern = null;
        this.tagClosingPrefix = null;

        this.tagPattern = '[\\w]';

        this.setOpening = function(pattern,defaultValue){
            this.openingPattern = pattern;
            this.opening = defaultValue;
            return this;
        }
        this.setClosing = function(pattern,defaultValue){
            this.closingPattern = pattern;
            this.closing = defaultValue;
            return this;
        }
        this.setTagSeparator = function(pattern,defaultValue){
            this.tagSeparatorPattern = pattern;
            this.tagSeparator = defaultValue;
            return this;
        }
        this.setTagOpeningPrefix = function(value){
            this.tagOpeningPrefix = value;
            this.tagOpeningPrefixPattern = escapeRegExp(this.tagOpeningPrefix);
            return this;
        }
        this.setTagClosingPrefix = function(value){
            this.tagClosingPrefix = value;
            this.tagClosingPrefixPattern = escapeRegExp(this.tagClosingPrefix);
            return this;
        }

        this.getSeparatorRegex = function(){
            return new RegExp(this.tagSeparatorPattern,'g');
        }
        this.getClosingRegex = function(){
            return new RegExp(this.closingPattern,'g');
        }

        this.getTagSearchingRegex = function(tag,prefix){
            const pattern = `${this.openingPattern}(?:${this.tagSeparatorPattern}+(?:${this.tagOpeningPrefixPattern}|${this.tagClosingPrefixPattern})${this.tagPattern})*${this.tagSeparatorPattern}+${prefix}${tag}(?:${this.tagSeparatorPattern}+(?:${this.tagOpeningPrefixPattern}|${this.tagClosingPrefixPattern})${this.tagPattern})*${this.tagSeparatorPattern}+${this.closingPattern}`;
            return new RegExp(pattern, "g");
        }
        this.getOpeningTagSearchingRegex = function(tag){
            return getTagSearchingRegex(tag,this.tagOpeningPrefixPattern);
        }
        this.getClosingTagSearchingRegex = function(tag){
            return getTagSearchingRegex(tag,this.tagClosingPrefixPattern);
        }

        this.getContainerSearchingRegex = function(){
            const pattern = `${this.openingPattern}(?:${this.tagSeparatorPattern}+(?:${this.tagOpeningPrefixPattern}|${this.tagClosingPrefixPattern})${this.tagPattern})*${this.tagSeparatorPattern}+${this.closingPattern}`;
            return new RegExp(pattern, "g");
        }

        this.addTagToContainer = function(containerString,tag,prefix){
            const separatorRegex = this.getSeparatorRegex();
            const lastSeparator = lastMatch(containerString,separatorRegex);
            const closingRegex = getClosingRegex();
            const closing = containerString.match(closingRegex)[0];
            const closingSubstringRegex = new RegExp(`${this.tagSeparsatorPattern}?${this.closingPattern}`,'g');
            const closingSubstring = containerString.match(closingSubstringRegex)[0];
            return containerString.replace(closingSubstring,`${lastSeparator?lastSeparator:this.tagSeparator}${prefix}${tag}${this.tagSeparator}${closing}`)
        }
        this.addOpeningTagToContainer = function(containerString,tag){
            return this.addTagToContainer(containerString,tag,this.tagOpeningPrefix);
        }
        this.addClosingTagToContainer = function(containerString,tag){
            return this.addTagToContainer(containerString,tag,this.tagClosingPrefix);
        }
    }

    function createTagsContainer(){
        let container = {
            oppeningPattern: '\\<\\!\\-{2}',
            defaultOppening: '<--',
            closingPattertn: '\\-{2}\\>',
            defaultClosing: '-->',
            tagSeparatorPattern: '\\s',
            deffaultTagSeparator: ' ',
            tagOpeningPrefix: '',
            tagClosingPrefix: '/'
        };
        container.instance = new TagContainer()
            .setOpening(container.oppeningPattern,container.defaultOppening)
            .setClosing(container.closingPattertn,container.defaultClosing)
            .setTagSeparator(container.tagSeparatorPattern,container.deffaultTagSeparator)
            .setTagOpeningPrefix(container.tagOpeningPrefix)
            .setTagClosingPrefix(container.tagClosingPrefix);
        container.regex = container.instance.getContainerSearchingRegex();
        return container;
    }

    function createIgnoringTag(){
        let tag = {
            name: 'ignoreAttchmentUpdating';
        };
        tag.openingRegex = tagsContainer.instance.getOpeningTagSearchingRegex(tag.name);
        tag.closingRegex = tagsContainer.instance.getClosingTagSearchingRegex(tag.name);
        return tag;
    }


    function init() {
        tagsContainer = createTagsContainer();
        ignoringTag = createIgnoringTag(); //TODO: TESTEAR ESTA MIERDA QUE SOLO ESCRIBÍ CÓDIGO A LO PENDEJO Y NO SÉ SI DE VERDAD FUNCIONA QUE MIERDA LAS PRUEBAS UNITARIAS PORQUE NO MEJOR USTED ME PRUEBA LA UNITARIA QUE TENGO ACÁ.
        refreshFoldersActionId = "refreshMediaAttachmentFolder";
        mediaPaths = [""].concat(mediaFolderPaths.split(pathSeparator));
        attachmentPaths =  [""].concat(attachmentFolderPaths.split(pathSeparator));
        script.registerCustomAction(refreshFoldersActionId, "Refresh folders: attachments", "Refresh folders: attachments", "", true);
    }

    function customActionInvoked(action) {
        if (action === refreshFoldersActionId) {
            updateCurrentNoteAttachments();
        }
    }

    function updateCurrentNoteAttachments(){
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

    function updateMediaFolder(pNoteContent,pNewPath){
        const mediaLineRegex = /(?:\!\[[^\r\n\]]+\]\([^\r\n\)]+\))|(?:\<img[^\>]*(?:\s|\"|\n)src\s*\=\s*\"[^\"]*\"[^\>]*\/\>)/g;
        const mediaLineFilter = (content, match)=>{return !isInsideTag(content,match.index)};
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
        const fileLineFilter = (content, match)=>{return !(isInsideTag(content,match.index) || mediaFromMDCheckRegex.test(match))};
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
                matches.push({line: match[0], index: match.index });
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

    function isInsideTag(pContent, pPosition,tag) {
        let lastStart = lastMatch(pContent, tag.openingRegex, 0, pPosition);
        let lastEnd = lastMatch(pContent, tag.closingRegex, 0, pPosition);
        let lastStartIndex = lastStart?lastStart.index:-1;
        let lastEndIndex = lastEnd?lastEnd.index:-1;

        return lastStartIndex !== -1 && (lastEndIndex === -1 || lastStartIndex > lastEndIndex);
    }

    function lastMatch(pContent, pRegex, pBeginnigIndex = 0, pEndingIndex = pContent.length){
        //seleccionar contenido
        const selectedContent = pContent.slice(pBeginnigIndex, pEndingIndex);

        //Verificar RegExp
        if (!pRegex.global) {
            let flags = "g";
            if (pRegex.ignoreCase) flags += "i";
            if (pRegex.multiline) flags += "m";
            pRegex = RegExp(pRegex.source, flags);
        }

        //Buscar último match
        let match;
        let lastMatch;
        while((match = pRegex.exec(selectedContent)) !== null){
            lastMatch ={line: match[0], index: match.index};
        }

        return lastMatch;
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
        return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    }
}
