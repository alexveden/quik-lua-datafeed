FROM debian:stable

##
## ===== Настройка окружения =====
##

USER root
ENV CONTAINER docker

## Настройка APT.
ENV DEBIAN_FRONTEND noninteractive
#COPY src/sources.list /etc/apt/sources.list
# RUN chmod 0644 /etc/apt/sources.list
# RUN chown root:root /etc/apt/sources.list
# RUN echo "debconf debconf/frontend select text" | debconf-set-selections && \
#     echo "debconf debconf/frontend select noninteractive" | debconf-set-selections && \
#     apt-get update && \
#     apt-get install -y --no-install-recommends apt-utils && \
#     apt-get autoremove -y --purge && \
#     apt-get clean -y && \
#     rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## Настройка локализации.
RUN apt-get update && \
    apt-get install -y --no-install-recommends locales tzdata && \
    sed -i 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen ru_RU.UTF-8 && \
    update-locale LANG=ru_RU.UTF-8 && \
    rm -f /etc/localtime && \
    ln -s /usr/share/zoneinfo/Europe/Moscow /etc/localtime && \
    apt-get autoremove -y --purge && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
ENV LANG ru_RU.UTF-8

## Установка пакетов для сборки.
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        bzip2 xz-utils \
        ca-certificates openssl \
        python3-minimal libpython3-stdlib git \
        make pkg-config autoconf automake libtool scons \
        mingw-w64 binutils-mingw-w64 wget \
        && \
    apt-get autoremove -y --purge && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## Обновление пакетов.
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get autoremove -y --purge && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## Настройка пользователя.
RUN useradd -u 1000 -d /home/user -m -s /bin/zsh user && \
    usermod -a -G sudo user && \
    mkdir -p /home/user/.config && \
    mkdir -p /home/user/.local/share && \
    chown -R user:user /home/user

## Смена пользователя.
USER user
ENV HOME /home/user
ENV TERM xterm-256color
WORKDIR /home/user

##
## ===== Сборка проекта =====
##

## Общие настройки сборки.
ENV CC x86_64-w64-mingw32-gcc
ENV CFLAGS -DDLL_EXPORT -DFD_SETSIZE=16384 -DZMQ_USE_SELECT -Os -fomit-frame-pointer -m64 -fPIC
ENV CXX x86_64-w64-mingw32-g++
ENV CXXFLAGS -Os -fomit-frame-pointer -m64 -fPIC

## Загрузка исходников lua.
ENV LUADIR $HOME/lua5.3
RUN cd $HOME && \
    wget https://www.lua.org/ftp/lua-5.3.5.tar.gz && \
    tar xf lua-5.3.5.tar.gz && \
    cd lua-5.3.5 && \
    make INSTALL_TOP=$LUADIR CC=x86_64-w64-mingw32-gcc TO_BIN="lua.exe luac.exe lua53.dll" mingw install 

RUN cp $LUADIR/bin/lua53.dll $HOME/lua53.dll.orig

RUN git clone https://github.com/diegonehab/luasocket.git && \
    cd luasocket/src && \
    make \
      prefix=$LUADIR/ \
      LDIR_mingw=bin/lua \
      CDIR_mingw=bin \
      LUAINC_mingw=$LUADIR/include \
      LUALIB_mingw=$LUADIR/bin/lua53.dll \
      CC_mingw=x86_64-w64-mingw32-gcc \
      LD_mingw=x86_64-w64-mingw32-gcc \
      PLAT=mingw \
      all install

## All files
RUN md5sum $HOME/lua53.dll.orig && \
    md5sum $LUADIR/bin/lua53.dll
