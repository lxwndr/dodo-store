// SPDX-FileCopyrightText: 2026 dodo-store authors
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.deepin.dtk 1.0
import "../components"

Item {
    id: root
    property var openDetail: null
    property string searchText: ""

    // With the store API enabled Home offers four curated lists; offline it
    // falls back to the two lists that can be derived locally.
    readonly property bool apiEnabled: flatpakBackend.storeApiEnabled
    readonly property var tabKeys: apiEnabled
        ? ["trending", "popular", "new", "updated"]
        : ["popular", "updated"]
    property int currentIndex: 0

    readonly property string currentKey:
        tabKeys.length > 0 ? tabKeys[Math.min(currentIndex, tabKeys.length - 1)] : ""
    readonly property var currentModel: tabModel(currentKey)
    readonly property string currentStatus: tabStatus(currentKey)
    readonly property bool searching: searchText.trim().length > 0
    readonly property var displayedModel: searching ? flatpakBackend.browseListModel : currentModel

    onSearchTextChanged: {
        if (searching)
            flatpakBackend.searchBrowse(searchText.trim())
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
        case "trending": return flatpakBackend.trendingModel
        case "popular": return flatpakBackend.popularModel
        case "new": return flatpakBackend.newModel
        case "updated": return flatpakBackend.updatedModel
        }
        return null
    }

    function tabStatus(key) {
        switch (key) {
        case "trending": return flatpakBackend.trendingStatus
        case "popular": return flatpakBackend.popularStatus
        case "new": return flatpakBackend.newStatus
        case "updated": return flatpakBackend.updatedStatus
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

        // Curated categories use the native DTK tab-button style.
        TabBar {
            Layout.alignment: Qt.AlignHCenter
            visible: !root.searching
            currentIndex: root.currentIndex
            onCurrentIndexChanged: {
                if (root.currentIndex !== currentIndex)
                    root.currentIndex = currentIndex
            }

            Repeater {
                model: root.tabKeys
                TabButton {
                    text: root.tabLabel(modelData)
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
                         ? flatpakBackend.busy && (!root.displayedModel || root.displayedModel.count === 0)
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
                visible: root.searching
                         ? !flatpakBackend.busy && (!root.displayedModel || root.displayedModel.count === 0)
                         : root.currentModel && root.currentModel.count === 0
                           && (root.currentStatus === "ok" || root.currentStatus === "stale")
                text: root.searching ? qsTr("No applications found.") : qsTr("No applications")
                color: palette.windowText
                opacity: 0.75
            }
        }
    }
}
