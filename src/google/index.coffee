run    = require './run.coffee'
google = require 'googleapis'
_      = require 'lodash'
path   = require 'path'
fs     = require 'fs'
Fiber  = require 'fibers'

module.exports = class


  # получить id видректории на google диске
  getDir: (dir) ->
    unless @_dirs[dir]?
      fiber = Fiber.current
      run (auth) =>
        service = google.drive('v3')
        service.files.list
          auth: auth
          q: "mimeType = 'application/vnd.google-apps.folder' and name='#{dir}' "
          fields: 'files(id, name)'
        , (err ,res) =>
          if res?.files?[0]?
            @_dirs[dir] = res.files[0].id
          do fiber.run
      do Fiber.yield

    return @_dirs[dir] if @_dirs[dir]?

  _dirs: []

  constructor: (data) ->
    @tmp = data.tmp

    # раз в 5 минут очищаем кеш директорий диска
    setInterval =>
      @_dirs = []
    , 5*60*1000


  get: (dir, files) ->
    files = [files] unless _.isArray files
    dir = @getDir dir if dir?

    result = []
    for file in files
      if _.isString file
        _file = @strFile(dir, file)
      else if _.isRegExp file
        _file = @regFile(dir, file)
      else
        continue
    for one in _file
      file = @getFile one
      unless _.isEmpty file
        result.push file

    return result

  strFile: (dir, file) ->
    fiber = Fiber.current

    q = "name='#{file}' and trashed=false"
    q += " and '#{dir}' in parents" if dir?

    run (auth) =>
      service = google.drive('v3')
      service.files.list
        auth: auth
        q: q
      , (err, res) =>
        if err? then fiber.run []
        else fiber.run res.files

    do Fiber.yield

  regFile: (dir, file) ->
    fiber = Fiber.current
    q = "trashed=false"
    q += " and '#{dir}' in parents" if dir?

    run (auth) =>
      service = google.drive('v3')
      service.files.list
        auth: auth
        q: q
      , (err, res) =>
        files = []
        unless err?
          for one in res.files
            if file.test one.name
              files.push one
        fiber.run files
    do Fiber.yield

  # получить локальные файлы
  getFile: (file) ->
    fiber = Fiber.current
    tmpFile = @tmp+'/'+file.name
    run (auth) =>
      service = google.drive('v3')
      service.files.get
        fileId: file.id
        alt: 'media'
        # fields: "properties"
        auth: auth
      , (err, res) =>
        # console.log res
        if err then fiber.run()
        else fs.writeFile tmpFile, res, (err ,res) =>
          # return
          if err then fiber.run()
          else
            fiber.run
              remote: file
              local: tmpFile
              remove: @remove
    Fiber.yield()

  remove: ->
    fiber = Fiber.current
    run (auth) =>
      service = google.drive('v3')
      service.files.delete
        fileId: @remote.id
        auth: auth
      , (err, res) =>
        fs.unlink @local, (err, res) =>
          do fiber.run
    do Fiber.yield
