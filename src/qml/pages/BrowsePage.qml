// SPDX-FileCopyrightText: 2026 dodo-store authors
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.deepin.dtk 1.0
import dodo.store 1.0
import "../components"

Item {
    id: root
    property var openDetail: null

    // The search field lives in the window title bar (DTK style); the page
    // only receives the text.
    property string searchText: ""
    property bool searchingAcrossRemotes: false

    onSearchTextChanged: {
        var hasSearch = searchText.trim().length > 0
        if (hasSearch && !searchingAcrossRemotes) {
            searchingAcrossRemotes = true
            flatpakBackend.refreshBrowseAllRemotes()
        } else if (!hasSearch && searchingAcrossRemotes) {
            searchingAcrossRemotes = false
            flatpakBackend.refreshBrowse()
        }
    }

    // Curated set of popular Flathub applications shown before the user searches.
    readonly property var popularAppIds: [
        "org.mozilla.firefox",
        "com.spotify.Client",
        "com.valvesoftware.Steam",
        "com.discordapp.Discord",
        "com.visualstudio.code",
        "org.libreoffice.LibreOffice",
        "org.gimp.GIMP",
        "org.videolan.VLC",
        "com.obsproject.Studio",
        "org.blender.Blender",
        "org.inkscape.Inkscape",
        "org.telegram.desktop",
        "org.kde.kdenlive",
        "org.audacityteam.Audacity",
        "org.kde.krita",
        "com.usebottles.bottles",
        "net.lutris.Lutris",
        "com.heroicgameslauncher.hgl",
        "org.prismlauncher.PrismLauncher",
        "com.github.tchx84.Flatseal",
        "io.github.flattool.Warehouse",
        "org.gnome.Boxes",
        "org.gnome.Calculator",
        "org.gnome.TextEditor"
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Label {
            Layout.fillWidth: true
            text: root.searchText.trim().length > 0
                  ? qsTr("Search results")
                  : qsTr("Popular on Flathub")
            font: DTK.fontManager.t8
            color: palette.windowText
        }

        BusyIndicator {
            Layout.alignment: Qt.AlignHCenter
            running: flatpakBackend.busy
            visible: running
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: 200
            cellHeight: 190
            focus: true

            model: AppFilterProxyModel {
                id: filterModel
                sourceModel: flatpakBackend.browseModel
                filterText: root.searchText.trim()
                appIdFilter: root.searchText.trim().length === 0
                             ? (flatpakBackend.popularAppIds.length > 0
                                ? flatpakBackend.popularAppIds : root.popularAppIds)
                             : []
            }

            delegate: AppCard {
                width: grid.cellWidth - 16
                height: grid.cellHeight - 16
                onClicked: {
                    if (root.openDetail)
                        root.openDetail(model.item)
                }
            }
        }

        Label {
            visible: grid.count === 0 && !flatpakBackend.busy
            Layout.alignment: Qt.AlignHCenter
            text: flatpakBackend.remotes.length === 0
                      ? qsTr("No Flatpak remotes configured.")
                      : qsTr("No applications found.")
            color: palette.windowText
        }
    }
}