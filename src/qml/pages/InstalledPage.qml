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
    property var backend: null
    property var openDetail: null
    property string searchText: ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        AppFilterProxyModel {
            id: installedModelFilter
            sourceModel: backend.installedModel
            hideRuntimes: true
            filterText: root.searchText
        }

        AppFilterProxyModel {
            id: installedCountModel
            sourceModel: installedModelFilter
            hideRuntimes: true
        }

        Label {
            Layout.fillWidth: true
            text: qsTr("%1 applications installed").arg(installedCountModel.count)
            font: DTK.fontManager.t8
            color: palette.windowText
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: AppFilterProxyModel {
                sourceModel: backend.installedModel
                hideRuntimes: true
                filterText: root.searchText
            }
            delegate: AppListItem {
                width: list.width
                appId: model.appId
                appName: model.name
                appSummary: model.summary
                appIcon: model.icon
                appVersion: model.version
                appBranch: model.branch
                appArch: model.arch
                isRuntime: model.isRuntime
                actionText: qsTr("Uninstall")
                onClicked: {
                    if (root.openDetail)
                        root.openDetail(model.item)
                }
                onActionClicked: backend.uninstallApp(appId, appBranch, appArch)
            }
        }

        Label {
            visible: list.count === 0 && !backend.busy
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Nothing installed yet.")
            color: palette.windowText
        }
    }
}