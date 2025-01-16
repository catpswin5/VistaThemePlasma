#include "executedlg.h"
#include "ui_executedlg.h"

void ExecuteDlg::executeFile()
{
    binary = new QProcess(this);

    QString input = ui->lineEdit->text();
    QStringList arguments = input.split(" ");
    QString program = arguments.takeFirst();
    if(program == "cmd")
        binary->startDetached("konsole");
    if(program == "winver")
        binary->startDetached("linver");
    else
        binary->startDetached(program, arguments);

    settings.setValue("lastExec", input);

    this->close();
}

ExecuteDlg::ExecuteDlg(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::ExecuteDlg)
{
    ui->setupUi(this);

    ui->lineEdit->setFocus(Qt::OtherFocusReason);
    ui->lineEdit->setText(settings.value("lastExec", "").toString());
    ui->okBtn->setEnabled(settings.value("lastExec", "").toString() != "");
}

void ExecuteDlg::on_cancelBtn_clicked()
{
    this->close();
}

void ExecuteDlg::on_okBtn_clicked()
{
    executeFile();
}

ExecuteDlg::~ExecuteDlg()
{
    if(ui->lineEdit->text() == "")
        settings.setValue("lastExec", "");

    delete ui;
}

void ExecuteDlg::on_browseBtn_clicked()
{
    filedlg = new QFileDialog();
    connect (filedlg, SIGNAL(fileSelected(QString)), this, SLOT(setCurrentFile(QString)));

    filedlg->show();
}
void ExecuteDlg::setCurrentFile(QString file)
{
    ui->lineEdit->setText(file);
}

void ExecuteDlg::on_lineEdit_returnPressed()
{
    if(ui->lineEdit->text() != "")
        executeFile();
}
void ExecuteDlg::on_lineEdit_textChanged(const QString &arg1)
{
    ui->okBtn->setEnabled(arg1 != "");
}

