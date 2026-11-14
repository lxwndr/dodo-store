// SPDX-FileCopyrightText: 2026 dodo-store authors
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.deepin.dtk 1.0
import org.deepin.dtk.style 1.0 as DS
import "../components"

Item {
    id: root
    property var backend: null
    property var openDetail: null
    property string searchText: ""
    property string searchError: ""
    property bool flathubSearchRequested: false

    function updateSearch() {
        if (!searching) {
            searchError = ""
            flathubSearchRequested = false
            backend.searchBrowse("")
            return
        }

        var flathub = null
        for (var i = 0; i < backend.remotesInfo.length; ++i) {
            var remote = backend.remotesInfo[i]
            if (remote.name === "flathub") {
                flathub = remote
                break
            }
        }

        if (!flathub || flathub.disabled || flathub.noEnumerate) {
            searchError = qsTr("Flathub is not available for search. Configure the Flathub remote in Repositories and try again.")
            flathubSearchRequested = false
            backend.searchBrowse("")
            return
        }

        searchError = ""
        // Search only the Flathub catalog. While it is loading, the view hides
        // any results left over from a previously selected remote.
        if (backend.currentRemote !== "flathub")
            backend.currentRemote = "flathub"
        if (!flathubSearchRequested) {
            flathubSearchRequested = true
            backend.refreshBrowse()
        }
        backend.searchBrowse(searchText.trim())
    }

    // With the store API enabled Home offers four curated lists; offline it
    // falls back to the two lists that can be derived locally.
    readonly property bool apiEnabled: backend.storeApiEnabled
    readonly property var tabKeys: apiEnabled
        ? ["trending", "popular", "new", "updated"]
        : ["popular", "updated"]
    property int currentIndex: 0

    readonly property string currentKey:
        tabKeys.length > 0 ? tabKeys[Math.min(currentIndex, tabKeys.length - 1)] : ""
    readonly property var currentModel: tabModel(currentKey)
    readonly property string currentStatus: tabStatus(currentKey)
    readonly property bool searching: searchText.trim().length > 0
    readonly property var displayedModel: searching ? backend.browseListModel : currentModel

    onSearchTextChanged: updateSearch()

    Connections {
        target: backend
        function onRemotesInfoChanged() {
            root.updateSearch()
        }
    }

    function tabLabel(key) {
        switch (key) {
        case "trending": return qsTr("Trending")
        case "popular": return qsTr("Popular")
        case "new": return qsTr("New")
        case "updated": return qsTr("Updated")
        }
        return ""
    }

    function tabModel(key) {
        switch (key) {
        case "trending": return backend.trendingModel
        case "popular": return backend.popularModel
        case "new": return backend.newModel
        case "updated": return backend.updatedModel
        }
        return null
    }

    function tabStatus(key) {
        switch (key) {
        case "trending": return backend.trendingStatus
        case "popular": return backend.popularStatus
        case "new": return backend.newStatus
        case "updated": return backend.updatedStatus
        }
        return ""
    }

    onApiEnabledChanged: currentIndex = 0

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 16

        Text {
            Layout.fillWidth: true
            text: root.searching ? qsTr("Search results") : qsTr("Discover applications")
            font: DTK.fontManager.t4
            color: palette.windowText
            elide: Text.ElideRight
        }

        // Curated categories in a single segmented pill.
        Item {
            Layout.alignment: Qt.AlignHCenter
            visible: !root.searching
            implicitWidth: root.tabKeys.length * 112
            width: implicitWidth
            height: 36

            Rectangle {
                anchors.fill: parent
                radius: DS.Style.control.radius
                color: Qt.alpha(palette.windowText, 0.06)
                border.width: 1
                border.color: Qt.alpha(palette.windowText, 0.08)
            }

            Rectangle {
                x: root.currentIndex * width
                width: parent.width / Math.max(1, root.tabKeys.length)
                height: parent.height
                radius: DS.Style.control.radius
                color: palette.highlight
                border.width: 1
                border.color: palette.highlight

                Behavior on x {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Row {
                anchors.fill: parent

                Repeater {
                    model: root.tabKeys

                    Item {
                        width: parent.width / Math.max(1, root.tabKeys.length)
                        height: parent.height

                        Text {
                            anchors.centerIn: parent
                            text: root.tabLabel(modelData)
                            color: index === root.currentIndex
                                   ? palette.highlightedText : palette.windowText
                            opacity: index === root.currentIndex ? 1.0 : 0.68
                            font: DTK.fontManager.t6
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentIndex = index
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridView {
                id: grid
                anchors.fill: parent
                clip: true
                cellWidth: 200
                cellHeight: 190
                visible: root.displayedModel && root.displayedModel.count > 0
                         && (!root.searching || !backend.busy)

                model: root.displayedModel

                delegate: AppCard {
                    width: grid.cellWidth - 16
                    height: grid.cellHeight - 16
                    onClicked: {
                        if (root.openDetail)
                            root.openDetail(model.item)
                    }
                }
            }

            BusyIndicator {
                anchors.centerIn: parent
                running: root.searching
                         ? backend.busy && (!root.displayedModel || root.displayedModel.count === 0)
                         : root.currentStatus === "loading"
                           && root.currentModel && root.currentModel.count === 0
                visible: running
            }

            Label {
                anchors.centerIn: parent
                visible: !root.searching && root.currentModel && root.currentModel.count === 0
                         && root.currentStatus === "error"
                text: qsTr("Failed to load. Check the store API settings and retry.")
                color: palette.windowText
                opacity: 0.75
            }

            Label {
                anchors.centerIn: parent
                width: parent.width * 0.8
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                visible: root.searching && root.searchError.length > 0
                text: root.searchError
                color: palette.windowText
                opacity: 0.75
            }

            Label {
                anchors.centerIn: parent
                visible: root.searching && root.searchError.length === 0
                         ? !backend.busy && (!root.displayedModel || root.displayedModel.count === 0)
                         : !root.searching && root.currentModel && root.currentModel.count === 0
                           && (root.currentStatus === "ok" || root.currentStatus === "stale")
                text: root.searching ? qsTr("No applications found.") : qsTr("No applications")
                color: palette.windowText
                opacity: 0.75
            }
        }
    }
}
