/*
 * Copyright (c) 2012-2013 Dickson Leong.
 * All rights reserved.
 *
 * This file is part of GagBook.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of GagBook nor the names of its contributors may be
 *       used to endorse or promote products derived from this software without
 *       specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import QtQuick 1.1
import com.nokia.symbian 1.1

Item {
    id: root

    property bool loadImage: false

    // Read-only
    property bool allowDelegateFlicking: gagImage.status === Image.Ready && gagImage.scale > pinchArea.minScale
    property bool imageZoomed: gagImage.scale !== pinchArea.minScale

    function saveImage() {
        return QMLUtils.saveImage(gagImage, model.id)
    }

    function resetImageZoom() {
        flickable.returnToBounds()
        bounceBackAnimation.to = pinchArea.minScale
        bounceBackAnimation.start()
    }

    height: ListView.view.height; width: ListView.view.width

    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: imageContainer.width; contentHeight: imageContainer.height
        clip: true
        interactive: moving || allowDelegateFlicking
        onHeightChanged: if (gagImage.status == Image.Ready) gagImage.fitToScreen()

        Item {
            id: imageContainer
            width: Math.max(gagImage.width * gagImage.scale, flickable.width)
            height: Math.max(gagImage.height * gagImage.scale, flickable.height)

            Image {
                id: gagImage

                property real prevScale

                function fitToScreen() {
                    scale = Math.min(flickable.width / width, flickable.height / height, 1)
                    pinchArea.minScale = scale
                    prevScale = scale
                }

                anchors.centerIn: parent
                smooth: !flickable.moving
                sourceSize.height: 3000
                cache: false
                fillMode: Image.PreserveAspectFit
                source: root.loadImage ? (settings.imageSize === 0 ? model.image.small : model.image.big) : ""

                onScaleChanged: {
                    if ((width * scale) > flickable.width) {
                        var xoff = (flickable.width / 2 + flickable.contentX) * scale / prevScale;
                        flickable.contentX = xoff - flickable.width / 2
                    }
                    if ((height * scale) > flickable.height) {
                        var yoff = (flickable.height / 2 + flickable.contentY) * scale / prevScale;
                        flickable.contentY = yoff - flickable.height / 2
                    }
                    prevScale = scale
                }

                onStatusChanged: {
                    if (status == Image.Ready) {
                        fitToScreen()
                        loadedAnimation.start()
                    }
                }

                NumberAnimation {
                    id: loadedAnimation
                    target: gagImage
                    property: "opacity"
                    duration: 250
                    from: 0; to: 1
                    easing.type: Easing.InOutQuad
                }

                Component.onCompleted: if (root.ListView.isCurrentItem) root.loadImage = true
            }
        }

        PinchArea {
            id: pinchArea

            property real minScale: 1.0
            property real maxScale: 3.0

            anchors.fill: parent
            enabled: gagImage.status === Image.Ready && !root.ListView.view.moving
            pinch.target: gagImage
            pinch.minimumScale: minScale * 0.5 // This is to create "bounce back effect"
            pinch.maximumScale: maxScale * 1.5 // when over zoomed

            onPinchStarted: scrollBar.flickableItem = flickable

            onPinchFinished: {
                flickable.returnToBounds()
                if (gagImage.scale < pinchArea.minScale) {
                    bounceBackAnimation.to = pinchArea.minScale
                    bounceBackAnimation.start()
                }
                else if (gagImage.scale > pinchArea.maxScale) {
                    bounceBackAnimation.to = pinchArea.maxScale
                    bounceBackAnimation.start()
                }
            }

            NumberAnimation {
                id: bounceBackAnimation
                target: gagImage
                duration: 250
                property: "scale"
                from: gagImage.scale
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: textContainer.state = textContainer.state ? "" : "hidden"
        }
    }

    Loader {
        anchors.centerIn: parent
        sourceComponent: {
            switch (gagImage.status) {
            case Image.Loading:
                return loadingIndicator
            case Image.Error:
                return failedLoading
            default:
                return undefined
            }
        }

        Component {
            id: loadingIndicator

            BusyIndicator {
                id: busyIndicator
                platformInverted: !settings.whiteTheme
                running: true
                width: platformStyle.graphicSizeLarge; height: width
            }
        }

        Component { id: failedLoading; Label { text: "Error loading image"; platformInverted: settings.whiteTheme } }
    }

    ScrollDecorator { id: scrollBar; flickableItem: null; platformInverted: settings.whiteTheme }

    Item {
        id: textContainer
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: textColumn.height + 2 * textColumn.anchors.margins
        states: State {
            name: "hidden"
            AnchorChanges { target: textContainer; anchors.top: undefined; anchors.bottom: root.top }
        }
        transitions: Transition { AnchorAnimation { duration: 250; easing.type: Easing.InOutQuad } }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.5
        }

        Column {
            id: textColumn
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: constant.paddingSmall }
            height: childrenRect.height

            Text {
                anchors { left: parent.left; right: parent.right }
                font.pixelSize: constant.fontSizeMedium
                color: "white"
                font.bold: true
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 2
                text: model.title
            }

            Text {
                anchors { left: parent.left; right: parent.right }
                font.pixelSize: constant.fontSizeMedium
                color: "white"
                elide: Text.ElideRight
                text: model.votes + " likes"
            }
        }
    }
}
