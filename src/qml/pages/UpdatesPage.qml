// SPDX-FileCopyrightText: 2026 dodo-store authors
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.deepin.dtk 1.0
import dodo.store 1.0
import "../components"

Item {
    id: root
    property var openDetail: null

    AppFilterProxyModel {
        id: appUpdatesModel
        sourceModel: flatpakBackend.updatesModel
        hideRuntimes: true
    }

    AppFilterProxyModel {
        id: runtimeUpdatesModel
        sourceModel: flatpakBackend.updatesModel
        showRuntimesOnly: true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Label {
                Layout.fillWidth: true
                text: qsTr("%1 application updates and %2 runtime updates")
                    .arg(appUpdatesModel.count).arg(runtimeUpdatesModel.count)
                font: DTK.fontManager.t8
                color: palette.windowText
            }
            Button {
                text: qsTr("Update All")
                enabled: flatpakBackend.updatesModel.count > 0 && !flatpakBackend.busy
                onClicked: flatpakBackend.updateAll()
            }
            Button {
                text: qsTr("Check for updates")
                onClicked: flatpakBackend.refreshInstalled()
            }
            Button {
                text: qsTr("Cancel")
                visible: flatpakBackend.busy
                onClicked: flatpakBackend.cancelOperation()
            }
        }

        BusyIndicator {
            Layout.alignment: Qt.AlignHCenter
            running: flatpakBackend.busy
            visible: running
        }

        Label {
            visible: appUpdatesModel.count > 0
            Layout.fillWidth: true
            text: qsTr("Application updates")
            font: DTK.fontManager.t6
            color: palette.windowText
        }

        ListView {
            id: appList
            visible: appUpdatesModel.count > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: appUpdatesModel.count * 56
            Layout.minimumHeight: 0
            clip: true
            spacing: 4
            model: appUpdatesModel
            delegate: AppListItem {
                width: appList.width
                actionText: qsTr("Update")
                onClicked: {
                    if (root.openDetail)
                        root.openDetail(model.item)
                }
                onActionClicked: flatpakBackend.updateApp(model.appId, model.branch, model.arch)
            }
        }

        Label {
            visible: runtimeUpdatesModel.count > 0
            Layout.fillWidth: true
            text: qsTr("Runtime updates")
            font: DTK.fontManager.t6
            color: palette.windowText
        }

        ListView {
            id: runtimeList
            visible: runtimeUpdatesModel.count > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: runtimeUpdatesModel.count * 56
            Layout.minimumHeight: 0
            clip: true
            spacing: 4
            model: runtimeUpdatesModel
            delegate: AppListItem {
                width: runtimeList.width
                actionText: qsTr("Update")
                onClicked: {
                    if (root.openDetail)
                        root.openDetail(model.item)
                }
                onActionClicked: flatpakBackend.updateApp(model.appId, model.branch, model.arch)
            }
        }

        Label {
            visible: flatpakBackend.updatesModel.count === 0 && !flatpakBackend.busy
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("You're up to date.")
            color: palette.windowText
        }
    }
}
