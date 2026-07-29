#!/bin/bash

# devz_notes_logseq_launcher.sh
# Launcher for cr_notes.lsdb (devz)
# home: /dpool/vcmain/dev/linux/devz_notes_logseq_launcher
# see AFN.md for details on setting Actions for Nautilus for launcher

# logseq-cli note:
# - Ensure that logseq cli is runnable from any context, including Nautilus Actions. 
# - Default node provided in linux may be used and is likely incompatible with logseq cli.
# - Therefore make sure that logseq-cli executable loads the correct node version using nvm.
# -- One solution to create a script called /usr/bin/node_init_4_root that loads the correct node version and is reusable for any script that needs node. This is the approach used in this launcher.
# -- Have logseq-cli launcher call /usr/bin/node_init_4_root

pc() { :; }
pc_raw(){ :; }

_DEBUG=true
_PWD=`pwd`
_OK=true
META_DIR=.devz
LOGSEQ_APPIMAGE="/home/timq/apps/logseq-db/Logseq-db-2.0.1/Logseq-linux-x86_64-2.0.1.AppImage"

# Debug initialization
if [ "$_DEBUG" == true ] || [ -n "$DEBUG_CWD" ]; then
    _DEBUG=true
    _DEBUG_LOG=/tmp/devz_notes_logseq_launcher_$(date '+%y%m%d').log
    source _debug.sh

    pc() {
        local message="$(date '+%y%m%d.%H%M%S') - $1"
        echo $message
        echo $message >> $_DEBUG_LOG
    }
    pc_raw() {
        local message="$1"
        echo $message
        echo $message >> $_DEBUG_LOG
    }

    pc "DEBUG: LOGSEQ_APPIMAGE: $LOGSEQ_APPIMAGE"
fi

# check if DEBUG_CWD is set, then change into it
if [ -n "$DEBUG_CWD" ]; then
    if [ -d "$DEBUG_CWD" ]; then
        pc "PWD before DEBUG_CWD: $_PWD"
        _PWD="$DEBUG_CWD"
    else
        pc "DEBUG_CWD is set but not a directory: $DEBUG_CWD"
        _OK=false
    fi
fi

if $_OK; then

    pc "PWD Used: $_PWD"

    # Get CR Name (current folder name)
    CR_NAME="$(basename "$_PWD")"

    LOGSEQ_GRAPH_NAME="CR_${CR_NAME}"
    META_PATH="$_PWD/$META_DIR"

    # check current folder for a directory called .devz
    if [ ! -d "$META_PATH" ];
    then
        echo "ERROR: Could not find directory $META_DIR in folder $_PWD" && _OK=false
    fi
fi

if $_OK; then
    LS_ROOT="$META_PATH/ls_root"
    LS_CONFIG_DIR="$LS_ROOT/.config/Logseq"
    LS_STATE_HOME="$LS_ROOT/logseq"
    LS_GRAPH_PATH="$LS_STATE_HOME/graphs/$LOGSEQ_GRAPH_NAME"

    if $_DEBUG; then
        pc "DEBUG: LS_ROOT: $LS_ROOT"
        pc "DEBUG: LS_CONFIG_DIR: $LS_CONFIG_DIR"
        pc "DEBUG: LS_STATE_HOME: $LS_STATE_HOME"
        pc "DEBUG: LS_GRAPH_PATH: $LS_GRAPH_PATH"
    fi

fi


# Build launch environment for programs
if $_OK; then

    LAUNCH_ENV=(
        "HOME=$LS_ROOT"
        "XDG_CONFIG_HOME=$LS_ROOT/.config"
        "XDG_STATE_HOME=$LS_ROOT/.local/state"
        "XDG_DATA_HOME=$LS_ROOT/.local/share"
        "XDG_CACHE_HOME=$LS_ROOT/.cache"
    )

    # Preserve GUI session variables when launched from Nautilus Actions.
    [ -n "${DISPLAY:-}" ] && LAUNCH_ENV+=("DISPLAY=$DISPLAY")
    [ -n "${WAYLAND_DISPLAY:-}" ] && LAUNCH_ENV+=("WAYLAND_DISPLAY=$WAYLAND_DISPLAY")
    [ -n "${XDG_RUNTIME_DIR:-}" ] && LAUNCH_ENV+=("XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR")
    [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] && LAUNCH_ENV+=("DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS")

    if [ -n "${XAUTHORITY:-}" ]; then
        LAUNCH_ENV+=("XAUTHORITY=$XAUTHORITY")
    elif [ -n "${HOME:-}" ] && [ -f "$HOME/.Xauthority" ]; then
        # If XAUTHORITY is unset, fallback to the current user's Xauthority file.
        LAUNCH_ENV+=("XAUTHORITY=$HOME/.Xauthority")
    fi

fi


if $_OK; then
    if [ ! -d "$LS_STATE_HOME" ];
    then

        if $_DEBUG; then
            pc "Logseq notes not found. Creating: $LS_GRAPH_PATH"
        fi

        mkdir -p "$LS_CONFIG_DIR"
        mkdir -p "$LS_STATE_HOME"

        # --- Create preferences.json ------
        cat > "$LS_CONFIG_DIR/preferences.json" <<EOL
{
    "current-graph": "$LS_GRAPH_PATH"
}
EOL

        # Create the Graph using logseq-cli
        if ! command -v node >/dev/null 2>&1; then
            pc "ERROR: node is not on PATH. Nautilus Actions may not load your shell profile." && _OK=false
        fi

        if ! command -v logseq-cli >/dev/null 2>&1; then
            pc "ERROR: logseq-cli is not on PATH. Use an absolute path or export PATH in Actions for Nautilus." && _OK=false
            if $_DEBUG; then
                pc "DEBUG: PATH: ${PATH:-<unset>}"
                pc "DEBUG: NVM_DIR: ${NVM_DIR:-<unset>}"
            fi
        fi

        if $_OK; then
            # Run CLI with the caller's normal environment. Only the target graph root needs to be custom.
            pc "Running command: logseq-cli --root-dir \"$LS_STATE_HOME\" graph create --graph \"$LOGSEQ_GRAPH_NAME\" with node version: $(node -v)"

            logseq-cli --root-dir "$LS_STATE_HOME" graph create --graph "$LOGSEQ_GRAPH_NAME" \
                > >(while IFS= read -r _line; do pc_raw "logseq-cli stdout: $_line"; done) \
                2> >(while IFS= read -r _line; do pc_raw "logseq-cli stderr: $_line"; done)
            _CLI_RC=$?
            pc "logseq-cli exit code: $_CLI_RC"

            if [ $_CLI_RC -ne 0 ]; then
                pc "ERROR: logseq-cli failed with exit code $_CLI_RC" && _OK=false
            fi
        fi

        # note: logseq db will create and store the settings in the db file!
        # I have tried every way but it will not allow me to override the default config.edn

    fi

else
    if $_DEBUG; then
        pc "Logseq notes found. Using: $LS_GRAPH_PATH"
    fi
fi


# Launch Logseq
if $_OK; then

    pc "Running command: $LOGSEQ_APPIMAGE --no-sandbox with env: \"${LAUNCH_ENV[@]}\""

    env "${LAUNCH_ENV[@]}" "$LOGSEQ_APPIMAGE" --no-sandbox \
                > >(while IFS= read -r _line; do pc "logseq stdout: $_line"; done) \
                2> >(while IFS= read -r _line; do pc "logseq stderr: $_line"; done)
    _CLI_RC=$?
    
    pc "logseq exit code: $_CLI_RC"

    if [ $_CLI_RC -ne 0 ]; then
        pc "Note: logseq exited with code $_CLI_RC"
    fi

else
    pc "ERROR: devz_notes_logseq_launcher.sh exited with errors"
fi