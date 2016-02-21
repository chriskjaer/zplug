#!/bin/zsh

__import "print/print"

__zplug::zplug::cache::tags() {
    local key

    for key in "${(k)zplugs[@]}"
    do
        echo "name:$key, $zplugs[$key]"
    done \
        | awk -f "$ZPLUG_ROOT/src/share/cache.awk"
}

__zplug::zplug::cache::load() {
    local key

    $ZPLUG_USE_CACHE || return 2
    if [[ -f $_ZPLUG_CACHE_FILE ]]; then
        &>/dev/null diff -b \
            <( \
            awk -f "$ZPLUG_ROOT/src/share/read_cache.awk" \
            "$_ZPLUG_CACHE_FILE" \
            ) \
            <( \
            for key in "${(k)zplugs[@]}"
            do \
                echo "name:$key, $zplugs[$key]"; \
            done \
            | awk -f "$ZPLUG_ROOT/src/share/cache.awk"
        )

        case $status in
            0)
                # same
                source "$_ZPLUG_CACHE_FILE"
                return $status
                ;;
            1)
                # differ
                ;;
            2)
                # error
                __zplug::print::print::die "zplug: cache: something wrong\n"
                ;;
        esac
    fi

    # if cache file doesn't find,
    # returns non-zero exit code
    return 1
}

__zplug::zplug::cache::update() {
    $ZPLUG_USE_CACHE || return 2
    if [[ $funcstack[2] != "__load__" ]]; then
        printf "[zplug] this function must be called by __load__\n" >&2
        return 2
    fi

    if [[ -f $_ZPLUG_CACHE_FILE ]]; then
        chmod a+w "$_ZPLUG_CACHE_FILE"
    fi

    {
        __zplug::print::print::put '#!/bin/zsh\n\n'
        __zplug::print::print::put '# This file was generated by zplug\n'
        __zplug::print::print::put '# *** DO NOT EDIT THIS FILE ***\n\n'
        __zplug::print::print::put '[[ $- =~ i ]] || exit\n'
        __zplug::print::print::put 'export PATH="%s:$PATH"\n' "$ZPLUG_HOME/bin"
        __zplug::print::print::put 'export ZSH=%s\n\n' "$ZPLUG_HOME/repos/$_ZPLUG_OHMYZSH"
        __zplug::print::print::put 'if $is_verbose; then\n'
        __zplug::print::print::put '  echo "Static loading..." >&2\n'
        __zplug::print::print::put 'fi\n'
        if (( $#load_plugins > 0 )); then
            __zplug::print::print::put 'source %s\n' "${(qqq)load_plugins[@]}"
        fi
        if (( $#load_fpaths > 0 )); then
            __zplug::print::print::put '\n# fpath\n'
            __zplug::print::print::put 'fpath=(\n'
            __zplug::print::print::put '%s\n' ${(u)load_fpaths}
            __zplug::print::print::put '$fpath\n'
            __zplug::print::print::put ')\n'
        fi
        __zplug::print::print::put 'compinit -C -d %s\n' "$ZPLUG_HOME/zcompdump"
        if (( $#nice_plugins > 0 )); then
            __zplug::print::print::put '\n# Loading after compinit\n'
            __zplug::print::print::put 'source %s\n' "${(qqq)nice_plugins[@]}"
        fi
        if (( $#lazy_plugins > 0 )); then
            __zplug::print::print::put '\n# Lazy loading plugins\n'
            __zplug::print::print::put 'autoload -Uz %s\n' "${(qqq)lazy_plugins[@]:t}"
        fi
        __zplug::print::print::put '\n# Hooks after load\n%s\n' "${hook_load_cmds[@]}"
        __zplug::print::print::put '\nreturn 0\n'
        __zplug::print::print::put '%s\n' "$(__zplug::zplug::cache::tags)"
    } >|"$_ZPLUG_CACHE_FILE"

    if [[ -f $_ZPLUG_CACHE_FILE ]]; then
        chmod a-w "$_ZPLUG_CACHE_FILE"
    fi
}
