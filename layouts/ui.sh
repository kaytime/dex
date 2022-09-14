#! /bin/bash

install_ui_layout() {
    add_repo_keys \
        55751E5D >/dev/null

    cp /configs/files/sources.list.neon.user /etc/apt/sources.list.d/neon-user-repo.list

    update

    puts "ADDING KUI."

    KUI_PKG='
        system-layer-ui
    '

    MISC_KUI_PKGS='
        cryptsetup
        cryptsetup-initramfs
        dialog
        dmsetup
        keyutils
        nohang
        vkbasalt
    '

    install_downgrades $KUI_PKG $MISC_KUI_PKGS

    rm \
        /etc/apt/sources.list.d/neon-user-repo.list

    remove_repo_keys \
        55751E5D >/dev/null

    update
}
