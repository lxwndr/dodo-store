// SPDX-FileCopyrightText: 2026 dodo-store authors
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import org.deepin.dtk.private 1.0 as P
import org.deepin.dtk.style 1.0 as DS

// Use a direct green background for update actions. DTK's ColorSelector can
// resolve custom D.Palette instances using the active theme family instead of
// the supplied CommonColor values, which caused the update button to inherit
// the theme's pink highlight. Keep the native DTK panel for all other actions.
Item {
    id: control
    property Item button
    property bool green: true

    Rectangle {
        anchors.fill: parent
        visible: control.green
        radius: DS.Style.control.radius
        color: !control.button || !control.button.enabled
               ? "#9BBDA5"
               : control.button.down ? "#278848"
               : control.button.hovered ? "#43B96A"
               : "#35A85B"
        border.width: 1
        border.color: !control.button || !control.button.enabled
                      ? "#AFC8B5"
                      : control.button.down ? "#216F3D"
                      : control.button.hovered ? "#369957"
                      : "#2F914E"
    }

    P.ButtonPanel {
        anchors.fill: parent
        visible: !control.green
        button: control.button
    }
}
