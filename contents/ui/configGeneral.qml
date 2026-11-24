import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_updateInterval: interval.value
    property alias cfg_showIcon: showIcon.checked
    property alias cfg_iconSize: iconSize.value
    property alias cfg_fontFamily: fontFamily.text
    property alias cfg_fontSize: fontSize.value
    property alias cfg_fontBold: fontBold.checked

    Kirigami.FormLayout {
        QQC2.SpinBox {
            id: interval
            Kirigami.FormData.label: i18n("Check every (sec):")
            from: 5; to: 3600
        }
        QQC2.CheckBox { id: showIcon; Kirigami.FormData.label: i18n("Show globe icon:") }
        QQC2.SpinBox {
            id: iconSize
            Kirigami.FormData.label: i18n("Icon size (px):")
            from: 8; to: 48
        }
        QQC2.TextField { id: fontFamily; Kirigami.FormData.label: i18n("Font family:") }
        QQC2.SpinBox {
            id: fontSize
            Kirigami.FormData.label: i18n("Font size (px, 0 = theme):")
            from: 0; to: 48
        }
        QQC2.CheckBox { id: fontBold; Kirigami.FormData.label: i18n("Bold:") }
    }
}
