fs    = require 'fs-extra'
exec  = require('child_process').exec
path  = require 'path'
_ = require 'lodash'
Fiber = require 'fibers'
# require './google'

# получить директорию для временных файлов
getTmpDir = (data) ->
  # если это первый вызов функции
  unless @dir
    # определяем директорию
    if data.tmp?
      dir = data.tmp
    else
      dir = __dirname+'/.tmp'

    # Создаем эту папку если ее нет
    unless fs.existsSync dir
      fs.mkdirsSync dir

    @dir = yes

  return dir


class Dataload
  constructor: (data) ->
    # создаем директорию для временных файлов
    data.tmp = getTmpDir data
    # массив для задач
    @_tasks = []

    # подключаем нужный диск
    @disk = switch data.type
      when 'yandex' then require "./yandex.coffee"
      when 'google' then require "./google/index.coffee"
      when 'fs' then require "./fs.coffee"
      else throw "cannot find disk #{data.type}"

    # создаем объект класса диска
    @disk = new @disk(data)

    # кодировка файлов
    @encoding = data.encoding
    # разделитель
    @divider  = data.divider
    # директория на диске
    @dir = data.dir

  # сохранить задание
  task: (data) ->
    # если не указан кодировка, но она есть у DataLoad
    if @encoding? and not data.encoding
      data.encoding = @encoding
    # если не указан разделитель, но он есть у DataLoad
    if @divider? and not data.divider
      data.divider = @divider
    # если не указана директория, но она есть у DataLoad
    if @dir and data.dir is undefined
      data.dir = @dir
    # сохраняем
    @_tasks.push data

  # запускаем процесс
  run: ->
    Fiber =>
      @make task for task in @_tasks
      setTimeout =>
        do @run
      , 3000
      return
    .run()

  # выполняем одну обработку
  make: (task) ->

    # определяем директорию
    dir = task.dir ? '/'
    # получаем массив файлов
    files = @disk.get(dir, task.files)
    # если есть файлы для обработки
    unless _.isEmpty files
      # объект для данных внутри обработки
      data = {}
      # если есть заголовок задачи - выводим его
      if task.title
        console.log task.title
      # выполняем task.before
      if task.before? then task.before data
      # выполняем task.make
      if task.make?
        for file in files
          # если указана кодировка файла - преобразуем в utf-8
          @iconv(task.encoding, file.local) if task.encoding
          # получаем содержимое файла
          content = @readFile file.local
          # удаляем файл
          # @remove file
          # разбиваем контент на строки
          for str in content.split("\r\n")
            str = _.trim str
            unless _.isEmpty str
              # разбиваем строку указанным разделителем
              str = str.split(task.divider)
              str = _.map str, (s) -> _.trim s
              # обрабатываем строку синхронно
              @makeStr task, data, str, path.basename(file.local)

          # удаляем файл
          # do file.remove


      # выполняем task.after
      if task.after? then task.after data, file
      # удаляем файлы
      do file.remove for file in files
      # все готово
      console.log "готово!" if task.title?

  # изменить кодировку файла
  iconv: (encoding, file) ->
    fiber = Fiber.current
    cmd = []
    dir = path.dirname file
    basename = path.basename file
    cmd.push "cd #{dir}" # переходим в директорию файла
    cmd.push "touch __#{basename}" # создаем временный файл
    cmd.push "iconv -f #{encoding} -t utf8 #{basename} > __#{basename}" #декодируем во временный файл
    cmd.push "mv -f __#{basename} #{basename}"
    cmd = cmd.join ';'
    exec cmd, (err, res) ->
      do fiber.run
    do Fiber.yield

  readFile: (file) ->
    fiber = Fiber.current
    fs.readFile file, 'utf8', (err, res) ->
      fiber.run res
    do Fiber.yield

  # удалить файл
  remove: (file) ->
    fiber = Fiber.current
    fs.remove file, ->
      do fiber.run
    do Fiber.yield

  # обрабатывает 1 строку файла (синхронно)
  makeStr: (task, data, str, file) ->
    fiber = Fiber.current
    # передаем указанной функции make обработку строки
    task.make data, str, file, ->
      # переходим к следующей строке
      do fiber.run
    do Fiber.yield

module.exports = Dataload
