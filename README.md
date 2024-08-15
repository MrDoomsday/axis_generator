# AXIS Generator
Pseudo-random traffic generator in axi stream format

Модуль широко настраивается под требования пользователя: 

+ параметризация длины. Модуль может выдавать пакеты фиксированной длины, либо проводить генерацию пакетов случайной длины из заданного диапазона (минимальная и максимальная длина)

+ параметризация номера канала. Модуль может выдавать пакеты на фиксированный канал (ID пакета), либо проводить генерацию каналов для пакетов из заданного диапазона (минимальное и максимальное значение канала)

+ параметризация времени задержки между генерируемыми пакетами. Модуль может приостанавливать генерацию пакетов на фиксированное время, либо на случайный интервал из заданного диапазона (минимальное и максимальное значение времени задержки)

+ возможность бесконечной генерации пакетов или заданного количества.

Особенности: 
+ псевдослучайная последовательность для шины tdata (2^512-битный LFSR)
+ управление по интерфейсу AXI Lite


The module is widely customizable to user requirements:

+ parameterization of length. The module can issue packets of a fixed length, or generate packets of random length from a given range (minimum and maximum length)

+ parameterization of the channel number. The module can issue packets on a fixed channel (packet ID), or generate channels for packets from a given range (minimum and maximum channel value)

+ parameterization of the delay time between generated packets. The module can pause the generation of packets for a fixed time, or for a random interval from a specified range (minimum and maximum delay time values)

+ the ability to endlessly generate packages or a specified number.

Peculiarities:
+ pseudo-random sequence for tdata bus (2^512-bit LFSR)
+ control via AXI Lite interface