// SPDX-FileCopyrightText: 2026 dodo-store authors
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.deepin.dtk 1.0

// Application tile for the home / browse grids. `model` provides the standard
// AppListModel roles (name/icon/...).
Rectangle {
    id: root
    property bool hovered: false
    signal clicked()
    color: hovered ? Qt.alpha(palette.highlight, 0.15) : "transparent"
    radius: 12
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        Rectangle {
            id: iconBadge
            Layout.alignment: Qt.AlignHCenter
            width: 72
            height: 72
            radius: 12
            color: palette.base

            Image {
                anchors.fill: parent
                anchors.margins: 8
                source: model.icon
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: true
                sourceSize { width: 128; height: 128 }

                onStatusChanged: {
                    if (status === Image.Error)
                        console.warn("Could not load app icon:", model.appId, source, "error:", status)
                }
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            // Fall back to the app id when no display name is available.
            text: model.name || model.appId
            font: DTK.fontManager.t7
            color: palette.windowText
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            maximumLineCount: 1
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: root.clicked()
    }
}
