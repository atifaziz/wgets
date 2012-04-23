[stdin, stdout, stderr]  = [WScript.StdIn, WScript.StdOut, WScript.StdErr]

About =
    name        : 'WGETS'
    version     : '1.1'
    majorVersion: 1
    minorVersion: 1
    copyright   : 'Copyright (c) Atif Aziz. All rights reserved.'
    authors     : [ name: 'Atif Aziz', href: 'http://www.raboof.com/' ]
    description : 'A non-interactive web retriever script.'
    license     :
        title: 'Creative Commons Attribution-ShareAlike 3.0 Unported License.'
        href : 'http://creativecommons.org/licenses/by-sa/3.0/'
    write : (writeln) ->
        writeln("#{@name} #{@version}  - #{@description}")
        writeln(@copyright)
        writeln()
        if @authors.length
            author = () -> "#{@name}, #{@href}"
            if @authors.length > 1
                writeln('Written by:')
                writeln('- ' + author.apply(a)) for a in authors
            else
                writeln('Written by ' + author.apply(@authors[0]))
            writeln()
        writeln(@license.title)
        writeln(" #{@license.href}")
        writeln()

writeln = (s) -> stdout.WriteLine(s)
write   = (s) -> stdout.Write(s)
echo    = (s) -> WScript.Echo(s)
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
        sb.push(path1)
        sb.push('\\') if path1.slice(-1) isnt '\\'
        sb.push(if path2.indexOf('\\') is 0 then path2.substring(1) else path2)
        sb.join('')

HTTP =
    getResponseHeaders : (http) ->
        headersText = http.getAllResponseHeaders()
        parser = /^([^\:\r]+)\:\s*(.+)$/gm
        headers = {}
        while (match = parser.exec(headersText))
            [name, value] = [match[1].trim().toLowerCase(), match[2].trim()]
            headers[name] = value
        headers

String::trim = () -> @replace(/^\s+|\s+$/g, '')

String::clipLeft = (width, decoration = '...') ->
    if @length <= width then @ else decoration + @[-width...]

class ProgramArgumentError extends Error
    constructor: (@message = 'Error with program argument.') ->
        super (@message += ' Use the /? for help.')

getFileNameFromURL = (url, defaultFileName) ->
    qIndex = url.indexOf('?')
    path = if qIndex >= 0 then url.substring(0, qIndex) else url
    lastSlashIndex = path.lastIndexOf('/')
    result = path.substring(lastSlashIndex + 1)
    if result.length > 0 then result else defaultFileName

main = (args) ->
    logo = args.isFlagged('logo')
    About.write((s) -> stderr.WriteLine(s)) if logo

    if args.unnamed.length is 0
        if logo
            return
        else
            throw new ProgramArgumentError('Missing URL.')

    url = args.unnamed[0]

    useStandardOutput = false
    httpStatusOnly    = args.isFlagged('status')
    httpHeadersOnly   = args.isFlagged('headers')
    dontOutputEntity  = httpStatusOnly or httpHeadersOnly

    if not dontOutputEntity
        if args.unnamed.length > 1
            outputFileName = args.unnamed[1]
            useStandardOutput = outputFileName is '-'
        else
            outputFileName = getFileNameFromURL(url, '')
            throw new Error('Unable to guess the output file name from the URL.') if outputFileName.length is 0

    http = new ActiveXObject('Microsoft.XMLHTTP')
    method = if dontOutputEntity then 'HEAD' else 'GET'
    http.open(method, url, false)
    http.send()

    httpStatus = "#{http.status} #{http.statusText}"

    writeln(httpStatus) if httpStatusOnly
    write(http.getAllResponseHeaders()) if httpHeadersOnly

    if dontOutputEntity
        return

    headers = HTTP.getResponseHeaders(http)
    contentLength = parseInt(-1 unless headers['content-length'])

    outputDirectory = args.getNamed('od') or ''
    outputPath = if outputDirectory.length > 0 then Path.combine(outputDirectory, outputFileName) else outputFileName

    throw new Error(httpStatus) unless 200 <= http.status < 300

    if useStandardOutput
        write(http.responseText)
    else
        stream = new ActiveXObject('ADODB.Stream')
        stream.Type = ADO.StreamTypeEnum.adTypeBinary
        stream.Open()
        stream.Write(http.responseBody)
        stream.SaveToFile(outputPath, ADO.SaveOptionsEnum.adSaveCreateOverWrite)
        write("Saved " + url.clipLeft(30) + " to #{outputPath}")
        write(" [#{contentLength} byte(s)]") if contentLength >= 0
        writeln('.')

try
    wshargs = WScript.Arguments
    args = (wsharg for wsharg in wshargs)
    args.unnamed = (wshargs.Unnamed.Item(i) for i in [0...wshargs.Unnamed.Count])
    args.getNamed  = (name) -> WScript.Arguments.Named.Item(name)
    args.isFlagged = (name) -> WScript.Arguments.Named.Exists(name)
    main(args)
catch e
    stderr.WriteLine(if not e.message then e.toString() else e.message)
    WScript.Quit(-1)
