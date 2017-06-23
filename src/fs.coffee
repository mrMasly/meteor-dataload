fs   = require 'fs'
path = require 'path'
Fiber = require 'fibers'

remove = ->
  fiber = Fiber.current
  fs.unlink @local, ->
    do fiber.run
  do Fiber.yield

module.exports = class

  constructor: (data) ->

  # возвращает массив файлов
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
        result.push
          local: one
          remove: remove

    return result

  # получить файл из строки
  strFile: (dir, file) ->
    file = path.normalize(dir+'/'+file)
    if fs.existsSync file then return [file]
    else return []

  # получить файл из регулярного выражения
  regFile: (dir, file) ->
    files = []
    return [] unless fs.existsSync dir
    scan = fs.readdirSync dir
    for one in scan
      if file.test one
        files.push path.normalize(dir+'/'+one)
    return files
