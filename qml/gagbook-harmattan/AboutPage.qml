/*
    Copyright (C) 2012  Dickson Leong
    This file is part of GagBook.

    GagBook is free software: you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
    License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with this program. If not, see http://www.gnu.org/licenses/.
*/

import QtQuick 1.1
import com.nokia.meego 1.0

Page {
    id: aboutPage

    tools: ToolBarLayout {
        ToolIcon {
            platformIconId: "toolbar-back"
            onClicked: pageStack.pop()
        }
    }

    Flickable {
        id: aboutPageFlickable
        anchors { top: pageHeader.bottom; bottom: parent.bottom; left: parent.left; right: parent.right }
        contentHeight: container.height

        Item {
            id: container
            width: aboutPageFlickable.width
            height: textColumn.height + buttonColumn.anchors.topMargin + buttonColumn.height + 2 * textColumn.anchors.margins

            Column {
                id: textColumn
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: constant.paddingMedium }
                height: childrenRect.height
                spacing: constant.paddingMedium

                Text {
                    anchors { left: parent.left; right: parent.right }
                    font.pixelSize: constant.fontSizeXXLarge
                    horizontalAlignment: Text.AlignHCenter
                    color: constant.colorLight
                    font.bold: true
                    text: "GagBook"
                }

                Text {
                    anchors { left: parent.left; right: parent.right }
                    font.pixelSize: constant.fontSizeMedium
                    horizontalAlignment: Text.AlignHCenter
                    color: constant.colorMid
                    text: "v" + APP_VERSION
                }

                Text {
                    anchors { left: parent.left; right: parent.right }
                    font.pixelSize: constant.fontSizeMedium
                    horizontalAlignment: Text.AlignHCenter
                    color: constant.colorLight
                    wrapMode: Text.Wrap
                    textFormat: Text.PlainText
                    text: "GagBook is a 9GAG app that allow you to view the post from 9GAG \
with a simple and native swipe-based UI. \
GagBook is using InfiniGAG API but not affiliated with 9GAG or InfiniGAG. \
This app may involve transmitting huge amount of data when downloading images.\n\n\
Copyright © 2012 Dickson\n\
GagBook is open source and licensed under LGPL v3"
                }
            }

            Column {
                id: buttonColumn
                anchors {
                    top: textColumn.bottom; topMargin: constant.paddingXXLarge
                    horizontalCenter: parent.horizontalCenter
                }
                width: 322; height: childrenRect.height
                spacing: constant.paddingMedium

                Button {
                    text: "Developer's Website"
                    onClicked: Qt.openUrlExternally(constant.devWebSite)
                }

                Button {
                    text: "Source Repository"
                    onClicked: Qt.openUrlExternally(constant.sourceRepoSite)
                }
            }
        }
    }

    ScrollDecorator { flickableItem: aboutPageFlickable }

    PageHeader {
        id: pageHeader
        text: "About"
    }
}
