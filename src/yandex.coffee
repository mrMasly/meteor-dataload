YandexDisk = require('yandex-disk').YandexDisk
path  = require 'path'
md5   = require 'md5'
fs    = require 'fs'
_     = require 'lodash'
Fiber = require 'fibers'

class Disk

  # конструктор
  constructor: (data) ->
    @disk = new YandexDisk(data.name, data.password)

    # if data.dir then @disk.cd data.dir
    @tmp = data.tmp

  # возвращает массив скаченных файлов
  get: (dir, files) ->
    files = [files] unless _.isArray files
    # собираем все найденные файлы в массив result
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
        # @removeFile one
        result.push file

    return result

  # получить файл из сторки
  strFile: (dir, file) ->
    fiber = Fiber.current
    file = path.normalize(dir+'/'+file)
    @disk.exists file, (err, res) ->
      if res is true then fiber.run([file])
      else fiber.run([])
    Fiber.yield()

  # получить файл из регулярного выражения
  regFile: (dir, file) ->
    fiber = Fiber.current
    @disk.readdir dir, (err, res) ->
      files = []
      if res?
        for one in res
          if file.test one.displayName
            files.push path.normalize(dir+'/'+one.displayName)
      fiber.run(files)
    Fiber.yield()

  # получить локальные файлы
  getFile: (file) ->
    fiber = Fiber.current
    tmpFile = @tmp+'/'+path.basename(file)
    @disk.downloadFile file, tmpFile, (err, res) =>
      if err? then fiber.run()
      else
        fiber.run
          remote: file
          local: tmpFile
          disk: @disk
          remove: @remove
    Fiber.yield()

  remove: ->
    fiber = Fiber.current
    # console.log 'start'
    @disk.remove @remote, (err, res) =>
      # console.log err, res
      fs.unlink @local, (err, res) =>
        do fiber.run
    do Fiber.yield

module.exports = Disk
