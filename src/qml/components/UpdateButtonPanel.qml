// SPDX-FileCopyrightText: 2026 dodo-store authors
//
// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.15
import org.deepin.dtk 1.0 as D
import org.deepin.dtk.private 1.0 as P
import org.deepin.dtk.style 1.0 as DS

// Reuses DTK's native ButtonPanel, changing only its palette for update actions.
// The panel retains DTK borders, shadows, corner radius and interaction states.
P.ButtonPanel {
    id: control
    property bool green: true

    D.Palette {
        id: greenBackground1
        normal.common: Qt.rgba(0.207843, 0.658824, 0.356863, 1)
        hovered.common: Qt.rgba(0.262745, 0.72549, 0.415686, 1)
        pressed.common: Qt.rgba(0.152941, 0.533333, 0.286275, 1)
        disabled.common: Qt.rgba(0.607843, 0.741176, 0.647059, 1)
    }
    D.Palette {
        id: greenBackground2
        normal.common: Qt.rgba(0.176471, 0.596078, 0.309804, 1)
        hovered.common: Qt.rgba(0.211765, 0.623529, 0.34902, 1)
        pressed.common: Qt.rgba(0.137255, 0.490196, 0.262745, 1)
        disabled.common: Qt.rgba(0.568627, 0.682353, 0.6, 1)
    }
    D.Palette {
        id: greenInsideBorder
        normal.common: Qt.rgba(0.34902, 0.741176, 0.470588, 1)
        hovered.common: Qt.rgba(0.439216, 0.8, 0.545098, 1)
        pressed.common: Qt.rgba(0.137255, 0.478431, 0.262745, 1)
        disabled.common: Qt.rgba(0.662745, 0.756863, 0.686275, 1)
    }
    D.Palette {
        id: greenOutsideBorder
        normal.common: Qt.rgba(0.14902, 0.486275, 0.262745, 1)
        hovered.common: Qt.rgba(0.176471, 0.552941, 0.301961, 1)
        pressed.common: Qt.rgba(0.113725, 0.4, 0.215686, 1)
        disabled.common: Qt.rgba(0.529412, 0.615686, 0.552941, 1)
    }
    D.Palette {
        id: greenDropShadow
        normal.common: Qt.rgba(0.12549, 0.419608, 0.223529, 0.25098)
        hovered.common: Qt.rgba(0.12549, 0.419608, 0.223529, 0.313725)
        pressed.common: Qt.rgba(0.12549, 0.419608, 0.223529, 0.188235)
        disabled.common: Qt.rgba(0.12549, 0.419608, 0.223529, 0.12549)
    }
    D.Palette {
        id: greenInnerShadow1
        normal.common: Qt.rgba(0.141176, 0.356863, 0.207843, 1)
        hovered.common: Qt.rgba(0.168627, 0.439216, 0.25098, 1)
        pressed.common: Qt.rgba(0.090196, 0.282353, 0.164706, 1)
        disabled.common: Qt.rgba(0.443137, 0.541176, 0.470588, 1)
    }
    D.Palette {
        id: greenInnerShadow2
        normal.common: Qt.rgba(0.227451, 0.603922, 0.345098, 1)
        hovered.common: Qt.rgba(0.282353, 0.666667, 0.403922, 1)
        pressed.common: Qt.rgba(0.14902, 0.490196, 0.270588, 1)
        disabled.common: Qt.rgba(0.568627, 0.678431, 0.596078, 1)
    }

    color1: green ? greenBackground1
                  : (button.highlighted ? DS.Style.highlightedButton.background1 : DS.Style.button.background1)
    color2: green ? greenBackground2
                  : (button.highlighted ? DS.Style.highlightedButton.background2 : DS.Style.button.background2)
    insideBorderColor: green ? greenInsideBorder
                             : (button.highlighted ? DS.Style.highlightedButton.border : DS.Style.button.insideBorder)
    outsideBorderColor: green ? greenOutsideBorder : DS.Style.button.outsideBorder
    dropShadowColor: green ? greenDropShadow
                           : (button.highlighted ? DS.Style.highlightedButton.dropShadow : DS.Style.button.dropShadow)
    innerShadowColor1: green ? greenInnerShadow1
                             : (button.highlighted ? DS.Style.highlightedButton.innerShadow1 : DS.Style.button.innerShadow1)
    innerShadowColor2: green ? greenInnerShadow2
                             : (button.highlighted ? DS.Style.highlightedButton.innerShadow2 : DS.Style.button.innerShadow2)
}
