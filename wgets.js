// Generated by CoffeeScript 1.3.1
var ADO, HTTP, Path, ProgramArgumentError, about, alert, args, echo, getFileNameFromURL, i, main, stderr, stdin, stdout, write, writeln, wsharg, wshargs, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

about = "WGETS 1.2  - A non-interactive web retriever script.\nCopyright (c) Atif Aziz. All rights reserved.\n\nWritten by Atif Aziz, http://www.raboof.com/\n\nCreative Commons Attribution-ShareAlike 3.0 Unported License.\n http://creativecommons.org/licenses/by-sa/3.0/";

_ref = [WScript.StdIn, WScript.StdOut, WScript.StdErr], stdin = _ref[0], stdout = _ref[1], stderr = _ref[2];

writeln = function(s, w) {
  if (w == null) {
    w = stdout;
  }
  return w.WriteLine(s);
};

write = function(s, w) {
  if (w == null) {
    w = stdout;
  }
  return w.Write(s);
};

echo = function(s) {
  return WScript.Echo(s);
};

alert = echo;

ADO = {
  SaveOptionsEnum: {
    adSaveCreateNotExist: 1,
    adSaveCreateOverWrite: 2
  },
  StreamTypeEnum: {
    adTypeBinary: 1,
    adTypeText: 2
  }
};

Path = {
  combine: function(path1, path2) {
    var sb;
    if (path1 == null) {
      path1 = '';
    }
    if (path2 == null) {
      path2 = '';
    }
    sb = [];
    sb.push(path1);
    if (path1.slice(-1) !== '\\') {
      sb.push('\\');
    }
    sb.push(path2.indexOf('\\') === 0 ? path2.substring(1) : path2);
    return sb.join('');
  }
};

HTTP = {
  getResponseHeaders: function(http) {
    var headers, headersText, match, name, parser, value, _ref1;
    headersText = http.getAllResponseHeaders();
    parser = /^([^\:\r]+)\:\s*(.+)$/gm;
    headers = {};
    while ((match = parser.exec(headersText))) {
      _ref1 = [match[1].trim().toLowerCase(), match[2].trim()], name = _ref1[0], value = _ref1[1];
      headers[name] = value;
    }
    return headers;
  }
};

String.prototype.trim = function() {
  return this.replace(/^\s+|\s+$/g, '');
};

String.prototype.clipLeft = function(width, decoration) {
  if (decoration == null) {
    decoration = '...';
  }
  if (this.length <= width) {
    return this;
  } else {
    return decoration + this.slice(-width);
  }
};

ProgramArgumentError = (function(_super) {

  __extends(ProgramArgumentError, _super);

  ProgramArgumentError.name = 'ProgramArgumentError';

  function ProgramArgumentError(message) {
    this.message = message != null ? message : 'Error with program argument.';
    ProgramArgumentError.__super__.constructor.call(this, (this.message += ' Use the /? for help.'));
  }

  return ProgramArgumentError;

})(Error);

getFileNameFromURL = function(url, defaultFileName) {
  var lastSlashIndex, path, qIndex, result;
  qIndex = url.indexOf('?');
  path = qIndex >= 0 ? url.substring(0, qIndex) : url;
  lastSlashIndex = path.lastIndexOf('/');
  result = path.substring(lastSlashIndex + 1);
  if (result.length > 0) {
    return result;
  } else {
    return defaultFileName;
  }
};

main = function(args) {
  var contentLength, dontOutputEntity, http, httpHeadersOnly, httpStatus, httpStatusOnly, logo, method, outputDirectory, outputFileName, outputPath, stream, url, useStandardOutput, _ref1;
  logo = args.isFlagged('logo');
  if (logo) {
    writeln(about, stderr);
  }
  if (args.unnamed.length === 0) {
    if (logo) {
      return;
    }
    throw new ProgramArgumentError('Missing URL.');
  }
  url = args.unnamed[0];
  useStandardOutput = false;
  httpStatusOnly = args.isFlagged('status');
  httpHeadersOnly = args.isFlagged('headers');
  dontOutputEntity = httpStatusOnly || httpHeadersOnly;
  if (!dontOutputEntity) {
    if (args.unnamed.length > 1) {
      outputFileName = args.unnamed[1];
      useStandardOutput = outputFileName === '-';
    } else {
      outputFileName = getFileNameFromURL(url, '');
      if (outputFileName.length === 0) {
        throw new Error('Unable to guess the output file name from the URL.');
      }
    }
  }
  http = new ActiveXObject('Microsoft.XMLHTTP');
  method = dontOutputEntity ? 'HEAD' : 'GET';
  http.open(method, url, false);
  http.send();
  httpStatus = "" + http.status + " " + http.statusText;
  if (httpStatusOnly) {
    writeln(httpStatus);
  }
  if (httpHeadersOnly) {
    write(http.getAllResponseHeaders());
  }
  if (dontOutputEntity) {
    return;
  }
  contentLength = parseInt(String(http.getResponseHeader('Content-Length')));
  outputDirectory = args.getNamed('od') || '';
  outputPath = outputDirectory.length > 0 ? Path.combine(outputDirectory, outputFileName) : outputFileName;
  if (!((200 <= (_ref1 = http.status) && _ref1 < 300))) {
    throw new Error(httpStatus);
  }
  if (useStandardOutput) {
    return write(http.responseText);
  } else {
    stream = new ActiveXObject('ADODB.Stream');
    stream.Type = ADO.StreamTypeEnum.adTypeBinary;
    stream.Open();
    stream.Write(http.responseBody);
    stream.SaveToFile(outputPath, ADO.SaveOptionsEnum.adSaveCreateOverWrite);
    write("Saved " + url.clipLeft(30) + (" to " + outputPath));
    if (contentLength >= 0) {
      write(" [" + contentLength + " byte(s)]");
    }
    return writeln('.');
  }
};

try {
  wshargs = WScript.Arguments;
  args = (function() {
    var _i, _len, _results;
    _results = [];
    for (_i = 0, _len = wshargs.length; _i < _len; _i++) {
      wsharg = wshargs[_i];
      _results.push(wsharg);
    }
    return _results;
  })();
  args.unnamed = (function() {
    var _i, _ref1, _results;
    _results = [];
    for (i = _i = 0, _ref1 = wshargs.Unnamed.Count; 0 <= _ref1 ? _i < _ref1 : _i > _ref1; i = 0 <= _ref1 ? ++_i : --_i) {
      _results.push(wshargs.Unnamed.Item(i));
    }
    return _results;
  })();
  args.getNamed = function(name) {
    return WScript.Arguments.Named.Item(name);
  };
  args.isFlagged = function(name) {
    return WScript.Arguments.Named.Exists(name);
  };
  main(args);
} catch (e) {
  writeln((!e.message ? e.toString() : e.message), stderr);
  WScript.Quit(-1);
}
