// SPDX-FileCopyrightText: 2026 dodo-store authors
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Controls 2.15
import org.deepin.dtk 1.0

// Shared visual style for primary Flatpak actions.
Button {
    id: root

    // "primary" = blue, "update" = green, "neutral" = palette default.
    property string actionType: "neutral"

    implicitWidth: 130
    implicitHeight: 36

    contentItem: Text {
        text: root.text
        font: DTK.fontManager.t6
        color: root.actionType === "neutral" ? palette.buttonText : "white"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: height / 2
        color: {
            if (root.actionType === "update")
                return root.pressed ? Qt.darker("#2ca34a", 1.15) : "#2ca34a"
            if (root.actionType === "primary")
                return root.pressed ? Qt.darker(palette.highlight, 1.15) : palette.highlight
            return palette.button
        }
        border.color: root.actionType === "neutral"
                      ? Qt.darker(palette.button, 1.08)
                      : "transparent"
        opacity: root.enabled ? 1 : 0.5
    }
}
