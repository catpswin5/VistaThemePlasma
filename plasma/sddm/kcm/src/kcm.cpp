#include "kcm.h"

#include <QFileInfo>
#include <QQuickWindow>
#include <QWindow>

#include <KPluginFactory>
#include <KAuth/Action>
#include <KAuth/ExecuteJob>
#include <KConfig>
#include <KConfigGroup>
#include <KSharedConfig>
#include <KCoreConfigSkeleton>

using namespace KAuth;

K_PLUGIN_CLASS_WITH_JSON(KcmSddmSmod, "kcm_sddmsmod.json")

static QString s_defaultConfig("/usr/share/sddm/themes/vista-theme-mod/theme.conf");
static QString s_userConfig("/usr/share/sddm/themes/vista-theme-mod/theme.conf.user");
static QString s_background("/usr/share/sddm/themes/vista-theme-mod/background");
static QString s_defaultBackground("/usr/share/sddm/themes/vista-theme-mod/default-background.jpg");

QString s_currentBackground = s_background;

KcmSddmSmod::KcmSddmSmod(QObject *parent, const KPluginMetaData &data)
    : KQuickManagedConfigModule(parent, data)
    , m_config{KSharedConfig::openConfig(s_defaultConfig)}
    , m_defaultsLoaded{false}
    , m_applied{false}
{
    setAuthActionName("io.gitgud.catpswin56.kcmsddmsmod.write");

    if(QFileInfo::exists(s_userConfig)) m_config->addConfigSources(QStringList() << s_userConfig);

    // genuinely don't know what this is for but adding it anyway
    registerSettings(new KCoreConfigSkeleton(m_config));

    setSupportsInstantApply(false);

    connect(this, &KQuickConfigModule::mainUiReady, this, &KcmSddmSmod::setupQmlConnections);
}

KcmSddmSmod::~KcmSddmSmod() = default;


void KcmSddmSmod::setupQmlConnections()
{
    connect(mainUi(), SIGNAL(changed()), this, SLOT(checkRepresentsDefaults()));
    connect(mainUi(), SIGNAL(changed()), this, SLOT(checkNeedsSave()));
}

void KcmSddmSmod::checkNeedsSave()
{
    KConfigGroup general = m_config->group("General");

    // i love this specific part of the code fr
    setNeedsSave(mainUi()->property("enableStartup").toBool() != general.readEntry("enableStartup", QVariant(true)).toBool()
                 || mainUi()->property("playSound").toBool() != general.readEntry("playSound", QVariant(true)).toBool()
                 || mainUi()->property("forceUserSelect").toBool() != general.readEntry("forceUserSelect", QVariant(false)).toBool()
                 || mainUi()->property("rdpBackground").toBool() != general.readEntry("rdpBackground", QVariant(false)).toBool()
                 || mainUi()->property("backgroundSrc").toUrl() != QUrl::fromLocalFile(s_currentBackground));
}

void KcmSddmSmod::checkRepresentsDefaults()
{
    KConfigGroup general = KConfig(s_defaultConfig).group("General");

    // this one too
    setRepresentsDefaults(mainUi()->property("enableStartup").toBool() == general.readEntry("enableStartup", QVariant(true)).toBool()
                          && mainUi()->property("playSound").toBool() == general.readEntry("playSound", QVariant(true)).toBool()
                          && mainUi()->property("forceUserSelect").toBool() == general.readEntry("forceUserSelect", QVariant(false)).toBool()
                          && mainUi()->property("rdpBackground").toBool() == general.readEntry("rdpBackground", QVariant(false)).toBool()
                          && mainUi()->property("backgroundSrc").toUrl() == QUrl::fromLocalFile(s_defaultBackground));

    m_defaultsLoaded = representsDefaults();
}


void KcmSddmSmod::defaults()
{
    KConfig defaultCfg(s_defaultConfig);
    KConfigGroup general = defaultCfg.group("General");

    mainUi()->setProperty("enableStartup", general.readEntry("enableStartup"));
    mainUi()->setProperty("playSound", general.readEntry("playSound"));
    mainUi()->setProperty("forceUserSelect", general.readEntry("forceUserSelect"));
    mainUi()->setProperty("rdpBackground", general.readEntry("rdpBackground"));

    mainUi()->setProperty("backgroundSrc", QVariant(QUrl::fromLocalFile(s_defaultBackground)));

    m_defaultsLoaded = true;
    setNeedsSave(m_applied);
}

void KcmSddmSmod::load()
{
    KConfigGroup general = m_config->group("General");

    mainUi()->setProperty("enableStartup", general.readEntry("enableStartup"));
    mainUi()->setProperty("playSound", general.readEntry("playSound"));
    mainUi()->setProperty("forceUserSelect", general.readEntry("forceUserSelect"));
    mainUi()->setProperty("rdpBackground", general.readEntry("rdpBackground"));

    if(!QFileInfo::exists(s_background))
        s_currentBackground = s_defaultBackground;
    else
        s_currentBackground = s_background;

    mainUi()->setProperty("backgroundSrc", QVariant(QUrl::fromLocalFile(s_currentBackground)));
}

void KcmSddmSmod::save()
{
    QVariantMap args;
    args["enableStartup"]   = mainUi()->property("enableStartup").toBool();
    args["playSound"]       = mainUi()->property("playSound").toBool();
    args["forceUserSelect"] = mainUi()->property("forceUserSelect").toBool();
    args["rdpBackground"] = mainUi()->property("rdpBackground").toBool();
    args["background"]      = mainUi()->property("backgroundSrc").toUrl();

    Action writeAction(QStringLiteral("io.gitgud.catpswin56.kcmsddmsmod.write"));
    writeAction.setHelperId(QStringLiteral("io.gitgud.catpswin56.kcmsddmsmod"));
    writeAction.setArguments(args);
    writeAction.setParentWindow(QWindow::fromWinId(mainUi()->window()->winId()));

    ExecuteJob *job = writeAction.execute();
    qDebug("executing write..");
    if(!job->exec()) {
        qDebug() << "KAuth returned an error code:" << job->error();
        setNeedsSave(true);
    }
    else {
        setNeedsSave(false);
        if(!m_defaultsLoaded) m_applied = true;
    }
}

#include "kcm.moc"
#include "moc_kcm.cpp"
