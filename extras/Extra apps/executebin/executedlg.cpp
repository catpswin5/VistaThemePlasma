#include "executedlg.h"
#include "ui_executedlg.h"

void ExecuteDlg::executeFile()
{
    binary = new QProcess(this);
    connect (binary, SIGNAL(started()), this, SLOT(finished()));

    QString program = ui->lineEdit->text();
    binary->startCommand(program);

    this->hide();
}

ExecuteDlg::ExecuteDlg(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::ExecuteDlg)
{
    ui->setupUi(this);

    ui->lineEdit->setFocus(Qt::OtherFocusReason);
    ui->okBtn->setEnabled(false);
}

void ExecuteDlg::finished()
{
    this->close();
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

