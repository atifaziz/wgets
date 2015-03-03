about = '''
    WGETS 1.2.2 - A non-interactive web retriever script.
    Copyright (c) Atif Aziz. All rights reserved.

    Written by Atif Aziz, http://www.raboof.com/

    Creative Commons Attribution-ShareAlike 3.0 Unported License.
     http://creativecommons.org/licenses/by-sa/3.0/
'''

[stdin, stdout, stderr]  = [WScript.StdIn, WScript.StdOut, WScript.StdErr]

writeln = (s, w = stdout) -> w.WriteLine s
write   = (s, w = stdout) -> w.Write s
echo    = (s) -> WScript.Echo s
alert   = echo

ADO =
    SaveOptionsEnum:
        adSaveCreateNotExist : 1
        adSaveCreateOverWrite: 2
    StreamTypeEnum:
        adTypeBinary: 1
        adTypeText  : 2

Path =
    combine : (path1 = '', path2 = '') ->
        sb = []
        sb.push path1
        sb.push '\\' if '\\' isnt path1.slice -1
        sb.push if (path2.indexOf '\\') is 0 then path2.substring(1) else path2
        sb.join ''

HTTP =
    getResponseHeaders : (http) ->
        headersText = http.getAllResponseHeaders!
        parser = /^([^\:\r]+)\:\s*(.+)$/gm
        headers = {}
        while mtch = parser.exec headersText
            [name, value] = [mtch[1].trim!.toLowerCase!, mtch[2].trim!]
            headers[name] = value
        headers

String::trim = -> @replace(/^\s+|\s+$/g, '')

String::clipLeft = (width, decoration = '...') ->
    if @length <= width then @ else decoration + @.slice -width

class ProgramArgumentError extends Error
    (@message = 'Error with program argument.') ->
        super <| @message += ' Use the /? for help.'

getFileNameFromURL = (url, defaultFileName) ->
    qIndex = url.indexOf '?'
    path = if qIndex >= 0 then url.substring 0, qIndex else url
    lastSlashIndex = path.lastIndexOf '/'
    result = path.substring (lastSlashIndex + 1)
    if result.length > 0 then result else defaultFileName

main = (args) !->
    logo = args.isFlagged 'logo'
    writeln about, stderr if logo

    if args.unnamed.length is 0
        return if logo
        throw new ProgramArgumentError 'Missing URL.'

    url = args.unnamed[0]

    useStandardOutput = false
    httpStatusOnly    = args.isFlagged 'status'
    httpHeadersOnly   = args.isFlagged 'headers'
    dontOutputEntity  = httpStatusOnly or httpHeadersOnly

    if not dontOutputEntity
        if args.unnamed.length > 1
            outputFileName = args.unnamed[1]
            useStandardOutput = outputFileName is '-'
        else
            outputFileName = getFileNameFromURL url, ''
            throw new Error 'Unable to guess the output file name from the URL.' if outputFileName.length is 0

    http = new ActiveXObject 'Microsoft.XMLHTTP'
    method = if dontOutputEntity then 'HEAD' else 'GET'
    http.open method, url, false
    http.send!

    httpStatus = "#{http.status} #{http.statusText}"

    writeln httpStatus if httpStatusOnly
    write http.getAllResponseHeaders! if httpHeadersOnly

    return if dontOutputEntity

    contentLength = http.getResponseHeader 'Content-Length' |> String |> parseInt

    outputDirectory = args.getNamed 'od' or ''
    outputPath = if outputDirectory.length > 0 then Path.combine outputDirectory, outputFileName else outputFileName

    throw new Error httpStatus unless 200 <= http.status < 300

    if useStandardOutput
        write http.responseText
    else
        new ActiveXObject 'ADODB.Stream'
            ..Type = ADO.StreamTypeEnum.adTypeBinary
            ..Open!
            ..Write http.responseBody
            ..SaveToFile outputPath, ADO.SaveOptionsEnum.adSaveCreateOverWrite
        write "Saved #{url.clipLeft 30} to #outputPath"
        write " [#{contentLength} byte(s)]" if contentLength >= 0
        writeln '.'

do ->
    try
        wshargs = WScript.Arguments
        args = [wshargs.item i for i til wshargs.length]
        args.unnamed = [wshargs.Unnamed.Item i for i til wshargs.Unnamed.Count]
        args.getNamed  = -> WScript.Arguments.Named.Item   it
        args.isFlagged = -> WScript.Arguments.Named.Exists it
        main args
    catch e
        writeln (if not e.message then e.toString! else e.message), stderr
        WScript.Quit -1
