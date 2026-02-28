#include "helper.h"

#include <QString>
#include <QFile>
#include <QFileInfo>
#include <QUrl>

#include <KConfig>
#include <KConfigGroup>

static QString s_defaultConfig(QStringLiteral("/usr/share/sddm/themes/vista-theme-mod/theme.conf"));
static QString s_userConfig(QStringLiteral("/usr/share/sddm/themes/vista-theme-mod/theme.conf.user"));
static QString s_background(QStringLiteral("/usr/share/sddm/themes/vista-theme-mod/background"));
static QString s_defaultBackground(QStringLiteral("/usr/share/sddm/themes/vista-theme-mod/default-background.jpg"));

ActionReply KCMHelper::write(const QVariantMap &args)
{
    qDebug("writing...");

    ActionReply reply;

    bool enableStartup = args[QStringLiteral("enableStartup")].toBool();
    bool playSound = args[QStringLiteral("playSound")].toBool();
    bool forceUserSelect = args[QStringLiteral("forceUserSelect")].toBool();
    bool rdpBackground = args[QStringLiteral("rdpBackground")].toBool();
    QString background = args[QStringLiteral("background")].toUrl().toLocalFile();

    if(background != s_background && !rdpBackground) {
        // get rid of the already existing one first
        if(QFileInfo::exists(s_background)) {
            QFile fi(s_background);

            if(!fi.remove()) {
                reply = ActionReply::HelperErrorReply();
                reply.setErrorDescription(fi.errorString());
                qDebug() << "fail to set background:" << fi.errorString();
                return reply;
            }
        }

        QFile file(background);

        // then copy the new one
        // doing this because the copy function doesnt overwrite and will return false instead
        if(!file.copy(s_background)) {
            reply = ActionReply::HelperErrorReply();
            reply.setErrorDescription(file.errorString());
            qDebug() << "fail to set background:" << file.errorString();
            return reply;
        }

        qDebug("background set successfully");
    }

    if(rdpBackground) {
        QFile file(s_background);

        if(!file.remove(s_background)) {
            reply = ActionReply::HelperErrorReply();
            reply.setErrorDescription(file.errorString());
            qDebug() << "fail to set property rdpBackground:" << file.errorString();
            return reply;
        }

        qDebug("successfully set rdp background");
    }

    KConfig cfg(s_userConfig);

    KConfig defaultCfg(s_defaultConfig);
    defaultCfg.copyTo(s_userConfig, &cfg);

    KConfigGroup group_cfg = cfg.group(QStringLiteral("General"));
    group_cfg.writeEntry(QStringLiteral("enableStartup"), enableStartup);
    group_cfg.writeEntry(QStringLiteral("playSound"), playSound);
    group_cfg.writeEntry(QStringLiteral("forceUserSelect"), forceUserSelect);
    group_cfg.writeEntry(QStringLiteral("rdpBackground"), rdpBackground);

    group_cfg.copyTo(&cfg);

    if(cfg.sync()) {
        qDebug("config synced succesfully");
        return reply;
    }

    reply = ActionReply::HelperErrorReply();
    reply.setErrorDescription(QStringLiteral("Could not sync configuration"));
    qDebug("fail to sync config");
    return reply;
}

KAUTH_HELPER_MAIN("io.gitgud.catpswin56.kcmsddmsmod", KCMHelper)
