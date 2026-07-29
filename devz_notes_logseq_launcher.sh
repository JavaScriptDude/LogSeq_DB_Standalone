# devz_notes_logseq_launcher.sh
# Launcher for cr_notes.lsdb (devz)
# home: /dpool/vcmain/dev/linux/devz_notes_logseq_launcher


#!/bin/bash
_OK=true
META_DIR=.devz
LOGSEQ_APPIMAGE="/home/timq/apps/logseq-db/Logseq-db-2.0.1/Logseq-linux-x86_64-2.0.1.AppImage"

# check if DEBUG_CWD is set, then change into it
if [ -n "$DEBUG_CWD" ]; then
    cd "$DEBUG_CWD" || {
        echo "ERROR: Could not change directory to $DEBUG_CWD" && _OK=false
    }
fi

# Get CR Name (current folder name)
CR_NAME="$(basename "$(pwd)")"

if $_OK; then
    LOGSEQ_GRAPH_NAME="CR_${CR_NAME}"
    CURRENT_DIR="$(pwd)"
    # check current folder for a directory called .devz
    if [ ! -d "$META_DIR" ];
    then
        echo "ERROR: Could not find directory $META_DIR in folder $CURRENT_DIR" && _OK=false
    fi
fi

if $_OK; then
    LS_ROOT=$CURRENT_DIR/$META_DIR/ls_root
    LS_CONFIG_DIR="$LS_ROOT/.config/Logseq"
    LS_STATE_HOME="$LS_ROOT/logseq"
    LS_GRAPH_PATH="$LS_STATE_HOME/graphs/DEVZ_NOTES"
    
    if [ ! -d "$LS_STATE_DIR" ];
    then
        mkdir -p "$LS_CONFIG_DIR"
        mkdir -p "$LS_STATE_HOME"

        export XDG_CONFIG_HOME="$LS_ROOT"
        export HOME="$LS_ROOT"

        # --- Create preferences.json ------
        cat > "$LS_CONFIG_DIR/preferences.json" <<EOL
{
    "current-graph": "$LS_GRAPH_PATH"
}
EOL

        # Create the Graph
        logseq-cli --root-dir "$LS_STATE_HOME" graph create --graph "$LOGSEQ_GRAPH_NAME"

        # note: logseq db will create and store the settings in the db file!
        # I have tried every way but it will not allow me to override the default config.edn

    fi

    # Launch Logseq
    "$LOGSEQ_APPIMAGE" --no-sandbox
fi
