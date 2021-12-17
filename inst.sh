#!/bin/bash
#Part 1: install the Arch Linux
_SWAP="+4G"
_ROOT="+100G"
_PCNAME="FMLAB"

function get_root_pass {
    echo -e "\033[7mВведите пароль root пользователя: \033[0m"
    arch-chroot /mnt passwd    
}

function pre_install {
# Добавление русской раскладки клавиатуры
    loadkeys ru                             
# Установка шрифта с поддержкой русского языка
    setfont cyr-sun16
# Установка обновления времени через интернет
    timedatectl set-ntp true
# Установка часового пояса
    timedatectl set-timezone Europe/Moscow    
}

function mbr_new_parts {
# Удаление всех существующих разделов
    echo -e "o\n w\n" | fdisk /dev/sda
# Создание разделов на жестком диске
    echo -e "n\n\n\n\n${_SWAP}\nt\n82\nn\n\n\n\n${_ROOT}\nn\n\n\n\n\nw" | fdisk /dev/sda
# Форматирование раздела swap
    echo y | mkfs.ext4 /dev/sda1
# Форматирование раздела root
    echo y | mkfs.ext4 /dev/sda2
# Форматирование раздела home
    echo y | mkfs.ext4 /dev/sda3
# Монтируем папку root и создаем папку home
    mkswap /dev/sda1
    swapon /dev/sda1
    mount /dev/sda2 /mnt
    mkdir /mnt/home
    mount /dev/sda3 /mnt/home
}

function install {
# Установка системы
    pacstrap /mnt base linux linux-firmware sudo nano dhcpcd
# Генерация файла fstab
    genfstab -U -p /mnt >> /mnt/etc/fstab
# Установка часового пояса
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime  
# Установка времени BIOS
    arch-chroot /mnt hwclock --systohc
# Настройка языка
    arch-chroot /mnt echo "en_US.UTF-8 UTF-8\nru_RU.UTF-8 UTF-8" > /etc/locale.gen
    arch-chroot /mnt locale-gen
    arch-chroot /mnt touch /etc/locale.conf
    arch-chroot /mnt echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
# Настройка компьютера
    arch-chroot /mnt touch /etc/hostname
    arch-chroot /mnt echo "${_PCNAME}" >> /mnt/etc/hostname
    arch-chroot /mnt sed -i "s/# See hosts(5) for details/127.0.0.1 localhost\n::1 localhost\n127.0.0.1 ${_PCNAME}ocaldomain ${_PCNAME}/g" /etc/hosts
}

function mbr_grub {
# Установка и настройка GRUB загрузчика
    pacstrap /mnt grub
    arch-chroot /mnt grub-install /dev/sda
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg 
    arch-chroot /mnt sed -i "s/# GRUB boot loader configuration/GRUB_DISABLE_OS_PROBER=false/g" /etc/default/grub
}

function exit_install {
    umount -R /mnt
    reboot
}

# Выбор таблицы разметки диска перед установкой
while [ -n "$1" ]
do
case "$1" in
-gpt) 
    echo -e "Добро пожаловать в установку ArchLinux by \033[7mFM\033[0m"
    echo -e "Выбрана разметка диска: \033[7m GPT \033[0m" 
    shift 1
    if [ -z "$1" ]; then 
    echo -e "\033[31mОшибка:\033[0m не задано имя компьютера "
    echo -e "Проверьте ввод команды: \033[7minstall.sh -gpt имя_компьютера\033[0m"
    exit 1
    else
    echo -e "Имя компьютера $1"
    fi
    ;;
-mbr)
    pre_install 
    echo -e "Добро пожаловать в установку ArchLinux by \033[7mFM\033[0m"
    echo -e "Выбрана разметка диска: \033[7m GPT \033[0m" 
    shift 1
    if [ -z "$1" ]; then 
    echo -e "\033[31mОшибка:\033[0m не задано имя компьютера "
    echo -e "Проверьте ввод команды: \033[7minstall.sh -gpt имя_компьютера\033[0m"
    exit 1
    else
    mbr_new_parts
    install
    mbr_grub
    exit_install
    fi
    ;;
*)
    echo -e "\033[31mОшибка:\033[0m не выбрана таблица разметки диска "
    echo -e "Проверьте ввод команды: \033[7minstall.sh -mbr или install.sh -gpt\033[0m"
    exit 1
    ;;
esac
shift
done

