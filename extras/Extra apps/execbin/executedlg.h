#ifndef EXECUTEDLG_H
#define EXECUTEDLG_H

#include <QMainWindow>
#include <QProcess>
#include <QFileDialog>
#include <QSettings>

QT_BEGIN_NAMESPACE
namespace Ui {
class ExecuteDlg;
}
QT_END_NAMESPACE

class ExecuteDlg : public QMainWindow
{
    Q_OBJECT

public:
    void executeFile();
    ExecuteDlg(QWidget *parent = nullptr);
    ~ExecuteDlg();

private slots:
    void on_okBtn_clicked();
    void on_cancelBtn_clicked();

    void on_browseBtn_clicked();
    void setCurrentFile(QString file);

    void on_lineEdit_returnPressed();
    void on_lineEdit_textChanged(const QString &arg1);

private:
    Ui::ExecuteDlg *ui;
    QFileDialog* filedlg;

    QProcess *binary;
    QSettings settings;
};
#endif // EXECUTEDLG_H
