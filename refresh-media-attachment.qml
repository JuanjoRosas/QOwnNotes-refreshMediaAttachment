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

    property variant mediaPaths;
    property variant attachmentPaths;
    property variant tagContainer;
    property variant ignoringTag;

    property string refreshAttachmentsActionId: "refeshAttachmentsFolders";
    property string ignoreThisSectionActionId: "refreshAttachment_ignoreSection";
    property string noticeThisSectionActionId: "refreshAttachment_noticeSection";
    property bool isTesting: true;//<-CHANGE THIS DEPENDING ON WHETHER YOU'RE TESTING OR NOT

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

    function textBoxClass(){
        this.lineBreakRegex = /\n/g;
        this.lineBreak = '\n';
        this.content = '';
        this.lines = [];

        this.setContent = function(pContent){
            this.content = pContent;
            this.lines = pContent.split(this.lineBreakRegex);
        }

        this.setLines = function(pLines){
            this.lines = pLines;
            this.content = this.lines.join(this.lineBreak);
        }
    }

    function tagContainerClass(){
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

        this.tagPattern = '[\\w]+';

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

        this.getDefault = function(){
            return `${this.opening}${this.tagSeparator}${this.closing}`;
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
            return this.getTagSearchingRegex(tag,this.tagOpeningPrefixPattern);
        }
        this.getClosingTagSearchingRegex = function(tag){
            return this.getTagSearchingRegex(tag,this.tagClosingPrefixPattern);
        }

        this.getContainerSearchingRegex = function(){
            const pattern = `${this.openingPattern}(?:${this.tagSeparatorPattern}+(?:${this.tagOpeningPrefixPattern}|${this.tagClosingPrefixPattern})${this.tagPattern})*${this.tagSeparatorPattern}+${this.closingPattern}`;
            return new RegExp(pattern, "g");
        }

        this.addTagToContainer = function(containerString,tag,prefix){
            const separatorRegex = this.getSeparatorRegex();
            const lastSeparator = lastMatch(containerString,separatorRegex);
            const closingRegex = this.getClosingRegex();
            const closing = containerString.match(closingRegex)[0];
            const closingSubstringRegex = new RegExp(`${this.tagSeparatorPattern}?${this.closingPattern}`,'g');
            const closingSubstring = containerString.match(closingSubstringRegex)[0];
            return containerString.replace(closingSubstring,`${lastSeparator?lastSeparator.line:this.tagSeparator}${prefix}${tag}${this.tagSeparator}${closing}`)
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
            openingPattern: '\\<\\!\\-{2}',
            defaultOpening: '<--',
            closingPattern: '\\-{2}\\>',
            defaultClosing: '-->',
            tagSeparatorPattern: '\\s',
            defaultTagSeparator: ' ',
            tagOpeningPrefix: '',
            tagClosingPrefix: '/'
        };
        container.instance = new tagContainerClass()
            .setOpening(container.openingPattern,container.defaultOpening)
            .setClosing(container.closingPattern,container.defaultClosing)
            .setTagSeparator(container.tagSeparatorPattern,container.defaultTagSeparator)
            .setTagOpeningPrefix(container.tagOpeningPrefix)
            .setTagClosingPrefix(container.tagClosingPrefix);
        container.regex = container.instance.getContainerSearchingRegex();
        container.default = container.instance.getDefault();
        container.addOpeningTagToContainer = container.instance.addOpeningTagToContainer;
        container.addClosingTagToContainer = container.instance.addClosingTagToContainer;
        return container;
    }

    function createIgnoringTag(){
        let tag = {
            name: 'ignoreAttchmentUpdating'
        };
        tag.openingRegex = tagContainer.instance.getOpeningTagSearchingRegex(tag.name);
        tag.closingRegex = tagContainer.instance.getClosingTagSearchingRegex(tag.name);
        return tag;
    }


    function init() {
        //Intialize some properties
        tagContainer = createTagsContainer();
        ignoringTag = createIgnoringTag();
        mediaPaths = [""].concat(mediaFolderPaths.split(pathSeparator));
        attachmentPaths =  [""].concat(attachmentFolderPaths.split(pathSeparator));

        //Register custom actions
        script.registerCustomAction(refreshAttachmentsActionId, "Refresh folders: attachments", "Refresh folders: attachments", "", true);
        script.registerCustomAction(ignoreThisSectionActionId, "Refresh folders: ignore this section", "Refresh folders: ignore this section", "", true);
        script.registerCustomAction(noticeThisSectionActionId, "Refresh folders: notice this section", "Refresh folders: notice this section", "", true);

        //TESTS
        if(isTesting)
            runTests();
    }

    function customActionInvoked(action) {
        switch(action){
            case refreshAttachmentsActionId:
                updateCurrentNoteAttachments();
                break;
            case ignoreThisSectionActionId:
                //TODO
                break;
            case noticeThisSectionActionId:
                //TODO
                break;
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
        const mediaLineFilter = (content, match)=>{return !isInsideTag(content,match.index,ignoringTag)};
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
        const fileLineFilter = (content, match)=>{return !(isInsideTag(content,match.index,ignoringTag) || mediaFromMDCheckRegex.test(match))};
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

    function rearrangeUnclosedTags(pContent, pTag){//TODO: CORREGIR
        const openingTags = countMatches(pContent,pTag.openingRegex);
        const closingTags = countMatches(pContent,pTag.closingRegex);

        const rearrangedTextBox = new textBoxClass();
        rearrangedTextBox.setContent(pContent);
        const unclosedOpeningTags = openingTags > closingTags ? openingTags - closingTags : 0;
        const unclosedClosingTags = closingTags > openingTags ? closingTags - openingTags : 0;

        const unclosedTags = unclosedOpeningTags + unclosedClosingTags;

        if (unclosedTags > 0){
            const defaultTagContainer = tagContainer.default;
            const openingTag = tagContainer.addOpeningTagToContainer(defaultTagContainer,pTag.name);
            const closingTag = tagContainer.addClosingTagToContainer(defaultTagContainer,pTag.name);

            const addedOpeningTags = Array(unclosedTags).fill(openingTag);
            const addedClosingTags = Array(unclosedTags).fill(closingTag);
            const addedTags = addedOpeningTags.concat(addedClosingTags);

            if (unclosedOpeningTags > 0)
                rearrangedTextBox.setLines(rearrangedTextBox.lines.concat(addedTags));
            else
                rearrangedTextBox.setLines(addedTags.concat(rearrangedTextBox.lines));
        }
        
        return {textBox: rearrangedTextBox, unclosedOpeningTags: unclosedOpeningTags, unclosedClosingTags: unclosedClosingTags};
    }

    function isInsideTag(pContent, pPosition, pTag) {
        let lastStart = lastMatch(pContent, pTag.openingRegex, 0, pPosition);
        let lastEnd = lastMatch(pContent, pTag.closingRegex, 0, pPosition);
        let lastStartIndex = lastStart?lastStart.index:-1;
        let lastEndIndex = lastEnd?lastEnd.index:-1;

        return lastStartIndex !== -1 && (lastEndIndex === -1 || lastStartIndex > lastEndIndex);
    }

    function countMatches(pContent, pRegex){
        return ((pContent || '').match(pRegex) || []).length;
    }

    function lastMatch(pContent, pRegex, pBeginnigIndex = 0, pEndingIndex = pContent.length){
        //seleccionar contenido
        const selectedContent = pContent.slice(pBeginnigIndex, pEndingIndex);

        //Verificar RegExp
        pRegex = addFlags(pRegex, 'g');

        //Buscar último match
        let match;
        let lastMatchToReturn;
        while((match = pRegex.exec(selectedContent)) !== null){
            lastMatchToReturn ={line: match[0], index:pBeginnigIndex + match.index};
        }

        return lastMatchToReturn;
    }

    function addFlags(pRegex, pFlags){
        const hasGlobal = pRegex.global;
        const hasIgnoreCase = pRegex.ignoreCase;
        const hasMultiline = pRegex.multiline;

        const globalFlag = 'g';
        const ignoreCaseFlag = 'i';
        const multilineFlag = 'm';
        
        const addGlobal = pFlags.includes(globalFlag);
        const addIgnoreCase = pFlags.includes(ignoreCaseFlag);
        const addMultiline = pFlags.includes(multilineFlag);

        let regexToReturn = pRegex;
        if ( addGlobal && !hasGlobal || addIgnoreCase && !hasIgnoreCase || addMultiline && !hasMultiline ) {
            let newFlags = `${addGlobal||hasGlobal?globalFlag:''}${addIgnoreCase||hasIgnoreCase?ignoreCaseFlag:''}${addMultiline||hasMultiline?multilineFlag:''}`;
            regexToReturn = new RegExp(regexToReturn.source, newFlags);
        }

        return regexToReturn;
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

    //TESTS
    function runTests(){
        script.log("Comenzando tests...");
        script.log("====TEXT BOX====");
        testTextBox();
        script.log("====ESCAPE REGEX====");
        testEscapeRegExp();
        script.log("====ADD FLAGS====");
        testAddFlags();
        script.log("====COUNT MATCHES====");
        testCountMatches();
        script.log("====LAST MATCH====");
        testLastMatch();
        script.log("====IS INSIDE TAG====");
        testIsInsideTag();
        script.log("Terminado.");
    }

    function assertEqual(actual, expected, testName) {
        if (actual === expected) {
            script.log(`✔️ ${testName}`);
        } else {
            script.log(`❌ ${testName} - esperado: "${expected}", obtenido: "${actual}"`);
        }
    }

    function testTextBox(){
        const arraysEqual = (arr1, arr2)=>{
            if (arr1.length != arr2.length)
                return false;
            for (let i = 0;i<arr1.length;i++) {
                if(arr1[i] !== arr2[i])
                    return false;
            }
            return true;
        }

        const textBoxTestObject = new textBoxClass();
        const testScenery = [
            {content: `Hola${textBoxTestObject.lineBreak}mundo${textBoxTestObject.lineBreak}!`, lines:['Hola','mundo','!']},
            {content: `Ningún line break`, lines:['Ningún line break']},
            {content: ``, lines:['']},
            {content: `Muchas palabras ${textBoxTestObject.lineBreak}por línea ${textBoxTestObject.lineBreak}parecen ser un test ${textBoxTestObject.lineBreak}al menos, ${textBoxTestObject.lineBreak}interesante.`, lines:['Muchas palabras ','por línea ','parecen ser un test ','al menos, ','interesante.']}
        ]

        for (let scenery of testScenery) {
            textBoxTestObject.setContent(scenery.content);
            assertEqual(arraysEqual(textBoxTestObject.lines, scenery.lines), true, `Evaluando TextBox: ${scenery.content}`);
            textBoxTestObject.setLines(scenery.lines);
            assertEqual(textBoxTestObject.content, scenery.content, `Evaluando TextBox: ${scenery.lines}`);
        }
    }

    function testEscapeRegExp() {
        const input = "c:/users/admin/documents/media";
        const expected = "c:/users/admin/documents/media";
        const actual = escapeRegExp(input);
        assertEqual(actual, expected, "escapeRegExp sin caracteres especiales");

        const input2 = "c:\\users\\admin\\media";
        const expected2 = "c:\\\\users\\\\admin\\\\media";
        const actual2 = escapeRegExp(input2);
        assertEqual(actual2, expected2, "escapeRegExp con backslashes");
    }

    function testAddFlags(){
        const flags = ['g','i','m'];
        const pattern = '\w';
        let baseRegex = null;
        let baseFlags = null;
        let newFlags = null;
        let newRegex = null;

        const arrayCombination = (array) => {
            const result = [];

            const helper = (start, combo) => {
                if (combo.length > 0) {
                    result.push([...combo]);
                }
                for (let i = start; i < array.length; i++) {
                    helper(i + 1, [...combo, array[i]]);
                }
            };

            helper(0, []);
            return result;
        };
        const flagsCombination = [[],...arrayCombination(flags)].map((x)=>x.join(''));

        const includesAll = (arr, values) => values.every(v => arr.includes(v));

        for(let i=0; i < flagsCombination.length; i++){
            baseFlags = flagsCombination[i];
            baseRegex = RegExp(pattern,baseFlags);
            for(let j=0; j < flagsCombination.length; j++){
                newFlags = flagsCombination[j];
                newRegex = addFlags(baseRegex, newFlags);
                assertEqual(includesAll(newRegex.flags, newFlags.split('').concat(baseFlags.split(''))), true, `Banderas base = ${baseFlags}. Banderas nuevas = ${newFlags}`);
            }
        }
    }

    function testCountMatches(){
        const characters =' ABCDEFGHIJKLMNOPQRSTUVWYZabcdefghijklmnopqrstuvwxyz0123456789°|¬!"#$%&/()@ñÑ=\\?\'¿¡´¨+*~{[^]}`,;.:-_';

        const generateString = (length)=>{
            let result = '';
            const charactersLength = characters.length;
            for ( let i = 0; i < length; i++ ) {
                result += characters.charAt(Math.floor(Math.random() * charactersLength));
            }

            return result;
        }

        const generatePattern =()=>{
            return `${generateString(1)}X${generateString(1)}X${generateString(1)}X${generateString(1)}`;
        };

        const regex_1 = /(?:[^X]X){3}[^X]/
        const regex_2 = /(?:[^X]X){3}[^X]/g
        let content = generateString(Math.floor(Math.random() * 10));
        for(let i = 0; i < 3; i++){
            assertEqual(countMatches(content,regex_1), i>0?1:0, `Regexp NO global con ${i} coincidencias`);
            assertEqual(countMatches(content,regex_2), i, `Regexp global con ${i} coincidencias`);
            content += generatePattern() + generateString(Math.floor(Math.random() * 10));
        }
    }

    function testLastMatch() {
        const content_1 = "line 1\nline 2\nline 3\nline 2 again";
        const regex_1 = /line 2/g;
        const match_1 = lastMatch(content_1, regex_1);
        assertEqual(match_1.line, "line 2", "lastMatch retorna la última coincidencia");
        assertEqual(match_1.index, 21, "lastMatch retorna el índice correcto");

        const content_2 = "line 1\nline 2\nline 3\nline 2 again";
        const regex_2 = /line 2/g;
        const firstPosition_2 = content_2.indexOf('line 2');
        const lastPosition_2 = content_2.indexOf('line 2',firstPosition_2+1);
        const match_2 = lastMatch(content_2, regex_2, firstPosition_2);
        assertEqual(match_2.line, "line 2", "lastMatch retorna la última coincidencia empezando en primera aparición");
        assertEqual(match_2.index, lastPosition_2, "lastMatch retorna el índice correcto");

        const content_3 = "line 1\nline 2\nline 3\nline 2 again";
        const regex_3 = /line 2/g;
        const firstPosition_3 = content_3.indexOf('line 2');
        const lastPosition_3 = content_3.indexOf('line 2',firstPosition_3+1);
        const match_3 = lastMatch(content_3, regex_3, firstPosition_3);
        assertEqual(match_3.line, "line 2", "lastMatch retorna la última coincidencia empezando primera aparición + 1");
        assertEqual(match_3.index, lastPosition_3, "lastMatch retorna el índice correcto");

        const content_4 = "line 1\nline 2\nline 3\nline 2 again";
        const regex_4 = /line 2/g;
        const line_4 = 'line 2';
        const firstPosition_4 = content_4.indexOf('line 2');
        const lastPosition_4 = content_4.indexOf('line 2',firstPosition_4+1);
        const match_4 = lastMatch(content_4, regex_4, 0, firstPosition_4+line_4.length);
        assertEqual(match_4.line, line_4, "lastMatch retorna la primera coincidencia terminando primera aparición + longitud");
        assertEqual(match_4.index, firstPosition_4, "lastMatch retorna el índice correcto");

        const content_5 = "line 1\nline 2\nline 3\nline 2 again";
        const regex_5 = /line 2/g;
        const line_5 = 'line 2';
        const firstPosition_5 = content_5.indexOf('line 2');
        const lastPosition_5 = content_5.indexOf('line 2',firstPosition_5+1);
        const match_5 = lastMatch(content_5, regex_5, 0, lastPosition_5);
        assertEqual(match_5.line, line_5, "lastMatch retorna la primera coincidencia terminando segunda aparición");
        assertEqual(match_5.index, firstPosition_5, "lastMatch retorna el índice correcto");

        const content_6 = "line 1\nline 2\nline 3\nline 2 again";
        const regex_6 = /line 2/g;
        const line_6 = 'line 2';
        const firstPosition_6 = content_6.indexOf('line 2');
        const lastPosition_6 = content_6.indexOf('line 2',firstPosition_6+1);
        const match_6 = lastMatch(content_6, regex_6, firstPosition_6, lastPosition_6);
        assertEqual(match_6.line, line_6, "lastMatch retorna la primera coincidencia terminando segunda aparición empezando primera aparicion");
        assertEqual(match_6.index, firstPosition_6, "lastMatch retorna el índice correcto");

        const content_7 = "line 1\nline 2\nline 3\nline 2 again";
        const regex_7 = /line 2/g;
        const line_7 = 'line 2';
        const firstPosition_7 = content_7.indexOf('line 2');
        const lastPosition_7 = content_7.indexOf('line 2',firstPosition_7+1);
        const match_7 = lastMatch(content_7, regex_7, firstPosition_7, lastPosition_7+line_7.length);
        assertEqual(match_7.line, line_7, "lastMatch retorna la ultima coincidencia terminando segunda aparición + longitud empezando primera aparicion");
        assertEqual(match_7.index, lastPosition_7, "lastMatch retorna el índice correcto");
    }

    function testIsInsideTag() {
        //BASIC IGNORING TAG
        const IgTag1 = {
            name: 'ignore'
        };
        IgTag1.openingRegex = /<\!-- ignore -->/g;
        IgTag1.closingRegex = /<\!-- \/ignore -->/g;

        const testName_1_it1 = "isInsideTag detecta por fuera de etiqueta básica 1."
        const content_1_it1 = "testContent\n<!-- /ignore -->\ntestContent\n<!-- ignore -->\ntestContent\n<!-- /ignore -->\ntestContent\n<!-- ignore -->\ntestContent\n";
        const position_1_it1 = content_1_it1.indexOf("testContent");
        assertEqual(isInsideTag(content_1_it1, position_1_it1, IgTag1), false, testName_1_it1);

        const testName_2_it1 = "isInsideTag detecta por fuera de etiqueta básica 2."
        const content_2_it1 = "testContent\n<!-- /ignore -->\ntestContent\n<!-- ignore -->\ntestContent\n<!-- /ignore -->\ntestContent\n<!-- ignore -->\ntestContent\n";
        const position_2_it1 = content_2_it1.indexOf("testContent",position_1_it1 + 1);
        assertEqual(isInsideTag(content_2_it1, position_2_it1, IgTag1), false, testName_2_it1);

        const testName_3_it1 = "isInsideTag detecta por dentro de etiqueta básica 1."
        const content_3_it1 = "testContent\n<!-- /ignore -->\ntestContent\n<!-- ignore -->\ntestContent\n<!-- /ignore -->\ntestContent\n<!-- ignore -->\ntestContent\n";
        const position_3_it1 = content_3_it1.indexOf("testContent",position_2_it1 + 1);
        assertEqual(isInsideTag(content_3_it1, position_3_it1, IgTag1), true, testName_3_it1);

        const testName_4_it1 = "isInsideTag detecta por fuera de etiqueta básica 3."
        const content_4_it1 ="testContent\n<!-- /ignore -->\ntestContent\n<!-- ignore -->\ntestContent\n<!-- /ignore -->\ntestContent\n<!-- ignore -->\ntestContent\n";
        const position_4_it1 = content_4_it1.indexOf("testContent",position_3_it1 + 1);
        assertEqual(isInsideTag(content_4_it1, position_4_it1, IgTag1), false, testName_4_it1);

        const testName_5_it1 = "isInsideTag detecta por dentro de etiqueta básica 2."
        const content_5_it1 ="testContent\n<!-- /ignore -->\ntestContent\n<!-- ignore -->\ntestContent\n<!-- /ignore -->\ntestContent\n<!-- ignore -->\ntestContent\n";
        const position_5_it1 = content_5_it1.indexOf("testContent",position_4_it1 + 1);
        assertEqual(isInsideTag(content_5_it1, position_5_it1, IgTag1), true, testName_5_it1);

        //IGNORING TAG USED IN SCRIPT
        const testName_1_it2 = "isInsideTag detecta por fuera de etiqueta compleja 1."
        const content_1_it2 = `<!-- tag5 /tag6 -->testContent\n<!-- tag1 /${ignoringTag.name} /tag2 tag3 tag4 -->\ntestContent\n<!-- /tag1 ${ignoringTag.name} tag2 -->\ntestContent\n<!-- /tag3 /${ignoringTag.name} /tag2 -->\ntestContent\n<!-- /tag6 -->\n<!-- ${ignoringTag.name} /tag4 -->\ntestContent\n<!-- /tag5 -->`;
        const position_1_it2 = content_1_it2.indexOf("testContent");
        assertEqual(isInsideTag(content_1_it2, position_1_it2, ignoringTag), false, testName_1_it2);

        const testName_2_it2 = "isInsideTag detecta por fuera de etiqueta compleja 2."
        const content_2_it2 = `<!-- tag5 /tag6 -->testContent\n<!-- tag1 /${ignoringTag.name} /tag2 tag3 tag4 -->\ntestContent\n<!-- /tag1 ${ignoringTag.name} tag2 -->\ntestContent\n<!-- /tag3 /${ignoringTag.name} /tag2 -->\ntestContent\n<!-- /tag6 -->\n<!-- ${ignoringTag.name} /tag4 -->\ntestContent\n<!-- /tag5 -->`;
        const position_2_it2 = content_2_it2.indexOf("testContent",position_1_it2 + 1);
        assertEqual(isInsideTag(content_2_it2, position_2_it2, ignoringTag), false, testName_2_it2);

        const testName_3_it2 = "isInsideTag detecta por dentro de etiqueta compleja 1."
        const content_3_it2 = `<!-- tag5 /tag6 -->testContent\n<!-- tag1 /${ignoringTag.name} /tag2 tag3 tag4 -->\ntestContent\n<!-- /tag1 ${ignoringTag.name} tag2 -->\ntestContent\n<!-- /tag3 /${ignoringTag.name} /tag2 -->\ntestContent\n<!-- /tag6 -->\n<!-- ${ignoringTag.name} /tag4 -->\ntestContent\n<!-- /tag5 -->`;
        const position_3_it2 = content_3_it2.indexOf("testContent",position_2_it2 + 1);
        assertEqual(isInsideTag(content_3_it2, position_3_it2, ignoringTag), true, testName_3_it2);

        const testName_4_it2 = "isInsideTag detecta por fuera de etiqueta compleja 3."
        const content_4_it2 = `<!-- tag5 /tag6 -->testContent\n<!-- tag1 /${ignoringTag.name} /tag2 tag3 tag4 -->\ntestContent\n<!-- /tag1 ${ignoringTag.name} tag2 -->\ntestContent\n<!-- /tag3 /${ignoringTag.name} /tag2 -->\ntestContent\n<!-- /tag6 -->\n<!-- ${ignoringTag.name} /tag4 -->\ntestContent\n<!-- /tag5 -->`;
        const position_4_it2 = content_4_it2.indexOf("testContent",position_3_it2 + 1);
        assertEqual(isInsideTag(content_4_it2, position_4_it2, ignoringTag), false, testName_4_it2);

        const testName_5_it2 = "isInsideTag detecta por dentro de etiqueta compleja 2."
        const content_5_it2 = `<!-- tag5 /tag6 -->testContent\n<!-- tag1 /${ignoringTag.name} /tag2 tag3 tag4 -->\ntestContent\n<!-- /tag1 ${ignoringTag.name} tag2 -->\ntestContent\n<!-- /tag3 /${ignoringTag.name} /tag2 -->\ntestContent\n<!-- /tag6 -->\n<!-- ${ignoringTag.name} /tag4 -->\ntestContent\n<!-- /tag5 -->`;
        const position_5_it2 = content_5_it2.indexOf("testContent",position_4_it2 + 1);
        assertEqual(isInsideTag(content_5_it2, position_5_it2, ignoringTag), true, testName_5_it2);
    }

    function testRearrangeUnclosedTags(){
        let tag = {
            name: 'ignore'
        };
        tag.openingRegex = tagContainer.instance.getOpeningTagSearchingRegex(tag.name);
        tag.closingRegex = tagContainer.instance.getClosingTagSearchingRegex(tag.name);

        testScenery = [];

        //TODO

        //Etiquetas de apertura sin cerrar

        //Etiquetas de cierre sin cerrar

        //Etiquetas de cierre y de apertura sin cerrar

        //Todas las etiquetas cerradas
    }
}
