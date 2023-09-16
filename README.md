# Quik Lua Datafeed

Quik is legacy Russian trading terminal used by 90% of Russian brokers. It has built-in support of LUA scripting language. 
This project is an attempt of building high quality code in LUA: OOP, unit testing, unit test mocks, code coverage. 


# О проекте
Универсальный фреймворк для экспорта любой информации доступной через LUA Quik. Построен на основе модульной архитектуры. 
Этот проект - возможность для меня изучить LUA, и понять возможно ли написать на этом языке, что-то более сложное чем простые
скрипты. Оказалось, что возможно создать полноценный ООП, реализовать юнит тесты, mocks, и coverage. 


## Статус проекта
В разработке, но 100% покрыт тестами. 

## В планах
* ParamsHandler - текущие котировки
* MetadataHandler - информация об активах (дата экспирации, страйк опциона, базовый актив, размер тика)
* OHLCHandler - история цен за период
* OptionChainHandler - доска опционов
* GenericTableHandler - экспорт любых доступных таблиц в Quik


## Установка
1. Сделать `git clone https://github.com/alexveden/quik-lua-datafeed.git`
2. Сделать копию `config.example.lua -> config.lua` в папке `quik-lua-datafeed`
3. Отредактировать конфиг под себя
4. Добавить `quik-lua-datafeed/quik_lua_datafeed_main.lua` в LUA скрипты Quik и запустить (LUA 5.3!)


## Архитектура
В папке `quik-lua-datafeed/handlers` можете найти варианты обработчиков данных от Quik, они подписываются на события или по 
таймеру вызывают API Квика для получения данных. Эти данные компонуются в таблицу LUA, и передаются на `transport`, который сериализует
`key` и `data`. 

Transport при сериализации для ключей из таблицы {'key', 'subkey1', 'mykey'}, по умолчанию создает строку вида "key#subkey1#mykey" 
(хотя это может зависеть от реализации каждого транспорта индивидуально). Данные - это обычная таблица ключ-значение, и по умолчанию
они сериализуются в JSON.

Transport одновременно выполняет роль интерфейса для хранилища данных.

## Виды handlers (в разработке)
см. `quik-lua-datafeed/handlers`

* QuikStats - собирает текущий статус Quik, сохраняет с ключом `{'quik', 'status'}` (транспорт -> "quik#status"), в данные идут все доступные
значения функции `getInfoParam`

## Виды transports
см. `quik-lua-datafeed/transports`

* TransportLog - пишет JSON в logger (полезно для отладки)
* TransportMemcached - сохраняет данные в Memcached server, с ключами вида "quik#status", данные JSON
* TransportSocket - передает данные через UDP socket, с ключами вида "quik#status", данные JSON


## Виды loggers
см. `quik-lua-datafeed/loggers`
* LoggerFile - пишет лог в файл
* LoggerSocket - пишет лог в UDP socket (сервер для чтения логов на Python `examples/socket_logger_server.py`)
* LoggerPrintDbgStr - лог через функцию `PrintDbgStr()`
* LoggerMulti - позволяет комбинировать несколько логгеров в 1


## Для разработчиков
* Системные требования
1. Lua 5.3. stand-alone
2. luarocks
3. Требуются пакеты
```
# для фреймворка (в папке quik-lua-datafeed/lib уже есть, для запуска тестов нужно поставить отдельно или прописать в пути)
luarocks install cjson
luarocks install luasocket

# для тестов
luarocks install luaunit
luarocks install luacov
luarocks install luacov-html
```
4. Пишите тесты, в каталог `/test/`

## Обратная связь
Буду рад любым вопросам в issues, и не забудьте поставить звезду если пользуетесь проектом!

