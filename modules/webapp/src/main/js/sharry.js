elmApp.ports.setAccount.subscribe(function(state) {
    localStorage.setItem('account', JSON.stringify(state));
});

elmApp.ports.removeAccount.subscribe(function() {
    localStorage.removeItem('account');
});

elmApp.ports.reloadPage.subscribe(function() {
    location.reload();
});

// semantic interop

elmApp.ports.setProgress.subscribe(function(selectorPercentError) {
    var selector = selectorPercentError[0];
    var percent = selectorPercentError[1];
    var error = selectorPercentError[2];
    percent = Math.round(percent * 100);
    $(selector).progress('set percent', percent);
    if (error) {
        $(selector).progress( "set error");
    }
});


// very nice, found here: https://gist.github.com/gordonbrander/2230317
var genId = function (prefix) {
    // Math.random should be unique because of its seeding algorithm.
    // Convert it to base 36 (numbers + letters), and grab the first x characters
    // after the decimal.
    var gen = function() {
        return Math.random().toString(36).substr(2);
    };

    var p = prefix || "";
    return p + gen() + gen();
};

elmApp.ports.makeRandomString.subscribe(function(prefix) {
    var s = genId(prefix);
    elmApp.ports.randomString.send(s);
});

// resumable interop

var sharryResumables = {};

var registerCallbacks = function(r, browseClass, dropClass) {
    var nodes0 = document.querySelectorAll(browseClass);
    if (nodes0.length == 1) {
        r.assignBrowse(nodes0[0]);
    } else {
        console.warn("No elements to bind browseButton");
    }
    var nodes1 = document.querySelectorAll(dropClass);
    if (nodes1.length == 1) {
        r.assignDrop(nodes1[0]);
    } else {
        console.warn("No elements to bind dropZone");
    }
    return nodes0.length + nodes1.length;
};

elmApp.ports.resumableRebind.subscribe(function(handle) {
    var r = sharryResumables[handle];
    if (r) {
        registerCallbacks(r, r.opts.browseClass, r.opts.dropClass);
    }
});

elmApp.ports.resumableStart.subscribe(function(handle) {
    var r = sharryResumables[handle];
    if (r) {
        r.upload();
    }
});

elmApp.ports.resumablePause.subscribe(function(handle) {
    var r = sharryResumables[handle];
    if (r) {
        r.pause();
    }
});

elmApp.ports.resumableCancel.subscribe(function(handle) {
    var r = sharryResumables[handle];
    if (r) {
        r.cancel();
    }
});

elmApp.ports.resumableRetry.subscribe(function(handleAndIds) {
    var handle = handleAndIds[0];
    var ids = handleAndIds[1];
    var r = sharryResumables[handle];
    if (r) {
        ids.forEach(function(id) {
            var file = r.getFromUniqueIdentifier(id);
            if (file) {
                file.retry();
            }
        });
    }
});

elmApp.ports.makeResumable.subscribe(function(cfg) {
    var id = cfg.handle || genId("u");
    var page = cfg.page;
    var browseClass = cfg.browseClass;
    var dropClass = cfg.dropClass;

    var makeFile = function(file) {
        var progress = 0;
        if (file.hasOwnProperty("process")) {
            progress = file.progress();
        }
        var completed = false;
        if (file.hasOwnProperty("isComplete")) {
            completed = file.isComplete();
        }
        var uploading = false;
        if (file.hasOwnProperty("isUploading")) {
            uploading = file.isUploading();
        }
        return {
            fileName: file.fileName || file.name,
            size: file.size,
            uniqueIdentifier: file.uniqueIdentifier || "",
            progress: progress,
            completed: completed,
            uploading: uploading
        };
    };
    if (!sharryResumables[id]) {
        if (cfg.maxFiles <= 0) {
            cfg.maxFiles = undefined;
        }
        if (cfg.maxFileSize <= 0) {
            cfg.maxFileSize = undefined;
        }
        cfg.chunkRetryInterval = 800;
        cfg.typeParameterName = "";
        cfg.method = "octet";
        cfg.query = { token: id };
        cfg.maxFileSizeErrorCallback = function(file, count) {
            if (file instanceof FileList && file.length > 0) {
                elmApp.ports.resumableMaxFileSizeError.send([page, makeFile(file.item(0))]);
            } else {
                elmApp.ports.resumableMaxFileSizeError.send([page, makeFile(file)]);
            }
        };
        cfg.maxFilesErrorCallback = function(file, count) {
            if (file instanceof FileList && file.length > 0) {
                elmApp.ports.resumableMaxFilesError.send([page, makeFile(file.item(0)), count]);
            } else {
                elmApp.ports.resumableMaxFilesError.send([page, makeFile(file), count]);
            }
        };
        var r = new Resumable(cfg);
        var n = registerCallbacks(r, browseClass, dropClass);
        if (n > 0) {
            sharryResumables[id] = r;

            r.on('uploadStart', function() {
                elmApp.ports.resumableStarted.send(page);
            });
            r.on('fileAdded', function(file, event) {
                elmApp.ports.resumableFileAdded.send([page, makeFile(file)]);
            });
            r.on('fileSuccess', function(file, message) {
                elmApp.ports.resumableFileSuccess.send([page, makeFile(file)]);
            });
            r.on('progress', function() {
                elmApp.ports.resumableProgress.send([page, r.progress()]);
            });
            r.on('complete', function() {
                elmApp.ports.resumableComplete.send(page);
            });
            r.on('pause', function() {
                elmApp.ports.resumablePaused.send(page);
            });
            r.on('error', function(message, file) {
                elmApp.ports.resumableError.send([page, message, makeFile(file)]);
            });

            elmApp.ports.resumableHandle.send([page, id]);
        }
    } else {
        registerCallbacks(sharryResumables[id], browseClass, dropClass);
    }
});
