/****************************************************************************
** Meta object code from reading C++ file 'seventasks.h'
**
** Created by: The Qt Meta Object Compiler version 68 (Qt 6.8.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../../src/seventasks.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'seventasks.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 68
#error "This file was generated using the moc from 6.8.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")
namespace {

#ifdef QT_MOC_HAS_STRINGDATA
struct qt_meta_stringdata_CLASSSevenTasksENDCLASS_t {};
constexpr auto qt_meta_stringdata_CLASSSevenTasksENDCLASS = QtMocHelpers::stringData(
    "SevenTasks",
    "mouseEventDetected",
    "",
    "getDominantColor",
    "QVariant",
    "src",
    "isActiveWindow",
    "wid",
    "getWindowAspectRatio",
    "disableBlurBehind",
    "QWindow*",
    "w",
    "sendMouseEvent",
    "QQuickItem*",
    "mouseArea",
    "setMouseGrab",
    "arg",
    "getPosition"
);
#else  // !QT_MOC_HAS_STRINGDATA
#error "qtmochelpers.h not found or too old."
#endif // !QT_MOC_HAS_STRINGDATA
} // unnamed namespace

Q_CONSTINIT static const uint qt_meta_data_CLASSSevenTasksENDCLASS[] = {

 // content:
      12,       // revision
       0,       // classname
       0,    0, // classinfo
       8,   14, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       1,       // signalCount

 // signals: name, argc, parameters, tag, flags, initial metatype offsets
       1,    0,   62,    2, 0x06,    1 /* Public */,

 // methods: name, argc, parameters, tag, flags, initial metatype offsets
       3,    1,   63,    2, 0x02,    2 /* Public */,
       6,    1,   66,    2, 0x02,    4 /* Public */,
       8,    1,   69,    2, 0x02,    6 /* Public */,
       9,    1,   72,    2, 0x02,    8 /* Public */,
      12,    1,   75,    2, 0x02,   10 /* Public */,
      15,    2,   78,    2, 0x02,   12 /* Public */,
      17,    1,   83,    2, 0x02,   15 /* Public */,

 // signals: parameters
    QMetaType::Void,

 // methods: parameters
    QMetaType::QColor, 0x80000000 | 4,    5,
    QMetaType::Bool, QMetaType::Int,    7,
    QMetaType::QRect, QMetaType::Int,    7,
    QMetaType::Void, 0x80000000 | 10,   11,
    QMetaType::Void, 0x80000000 | 13,   14,
    QMetaType::Void, QMetaType::Bool, 0x80000000 | 10,   16,   11,
    QMetaType::QPointF, 0x80000000 | 13,   11,

       0        // eod
};

Q_CONSTINIT const QMetaObject SevenTasks::staticMetaObject = { {
    QMetaObject::SuperData::link<Plasma::Applet::staticMetaObject>(),
    qt_meta_stringdata_CLASSSevenTasksENDCLASS.offsetsAndSizes,
    qt_meta_data_CLASSSevenTasksENDCLASS,
    qt_static_metacall,
    nullptr,
    qt_incomplete_metaTypeArray<qt_meta_stringdata_CLASSSevenTasksENDCLASS_t,
        // Q_OBJECT / Q_GADGET
        QtPrivate::TypeAndForceComplete<SevenTasks, std::true_type>,
        // method 'mouseEventDetected'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        // method 'getDominantColor'
        QtPrivate::TypeAndForceComplete<QColor, std::false_type>,
        QtPrivate::TypeAndForceComplete<QVariant, std::false_type>,
        // method 'isActiveWindow'
        QtPrivate::TypeAndForceComplete<bool, std::false_type>,
        QtPrivate::TypeAndForceComplete<int, std::false_type>,
        // method 'getWindowAspectRatio'
        QtPrivate::TypeAndForceComplete<QRect, std::false_type>,
        QtPrivate::TypeAndForceComplete<int, std::false_type>,
        // method 'disableBlurBehind'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<QWindow *, std::false_type>,
        // method 'sendMouseEvent'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<QQuickItem *, std::false_type>,
        // method 'setMouseGrab'
        QtPrivate::TypeAndForceComplete<void, std::false_type>,
        QtPrivate::TypeAndForceComplete<bool, std::false_type>,
        QtPrivate::TypeAndForceComplete<QWindow *, std::false_type>,
        // method 'getPosition'
        QtPrivate::TypeAndForceComplete<QPointF, std::false_type>,
        QtPrivate::TypeAndForceComplete<QQuickItem *, std::false_type>
    >,
    nullptr
} };

void SevenTasks::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        auto *_t = static_cast<SevenTasks *>(_o);
        (void)_t;
        switch (_id) {
        case 0: _t->mouseEventDetected(); break;
        case 1: { QColor _r = _t->getDominantColor((*reinterpret_cast< std::add_pointer_t<QVariant>>(_a[1])));
            if (_a[0]) *reinterpret_cast< QColor*>(_a[0]) = std::move(_r); }  break;
        case 2: { bool _r = _t->isActiveWindow((*reinterpret_cast< std::add_pointer_t<int>>(_a[1])));
            if (_a[0]) *reinterpret_cast< bool*>(_a[0]) = std::move(_r); }  break;
        case 3: { QRect _r = _t->getWindowAspectRatio((*reinterpret_cast< std::add_pointer_t<int>>(_a[1])));
            if (_a[0]) *reinterpret_cast< QRect*>(_a[0]) = std::move(_r); }  break;
        case 4: _t->disableBlurBehind((*reinterpret_cast< std::add_pointer_t<QWindow*>>(_a[1]))); break;
        case 5: _t->sendMouseEvent((*reinterpret_cast< std::add_pointer_t<QQuickItem*>>(_a[1]))); break;
        case 6: _t->setMouseGrab((*reinterpret_cast< std::add_pointer_t<bool>>(_a[1])),(*reinterpret_cast< std::add_pointer_t<QWindow*>>(_a[2]))); break;
        case 7: { QPointF _r = _t->getPosition((*reinterpret_cast< std::add_pointer_t<QQuickItem*>>(_a[1])));
            if (_a[0]) *reinterpret_cast< QPointF*>(_a[0]) = std::move(_r); }  break;
        default: ;
        }
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        switch (_id) {
        default: *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType(); break;
        case 4:
            switch (*reinterpret_cast<int*>(_a[1])) {
            default: *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType(); break;
            case 0:
                *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType::fromType< QWindow* >(); break;
            }
            break;
        case 5:
            switch (*reinterpret_cast<int*>(_a[1])) {
            default: *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType(); break;
            case 0:
                *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType::fromType< QQuickItem* >(); break;
            }
            break;
        case 6:
            switch (*reinterpret_cast<int*>(_a[1])) {
            default: *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType(); break;
            case 1:
                *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType::fromType< QWindow* >(); break;
            }
            break;
        case 7:
            switch (*reinterpret_cast<int*>(_a[1])) {
            default: *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType(); break;
            case 0:
                *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType::fromType< QQuickItem* >(); break;
            }
            break;
        }
    } else if (_c == QMetaObject::IndexOfMethod) {
        int *result = reinterpret_cast<int *>(_a[0]);
        {
            using _t = void (SevenTasks::*)();
            if (_t _q_method = &SevenTasks::mouseEventDetected; *reinterpret_cast<_t *>(_a[1]) == _q_method) {
                *result = 0;
                return;
            }
        }
    }
}

const QMetaObject *SevenTasks::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *SevenTasks::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_meta_stringdata_CLASSSevenTasksENDCLASS.stringdata0))
        return static_cast<void*>(this);
    return Plasma::Applet::qt_metacast(_clname);
}

int SevenTasks::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = Plasma::Applet::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 8)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 8;
    } else if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 8)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 8;
    }
    return _id;
}

// SIGNAL 0
void SevenTasks::mouseEventDetected()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}
QT_WARNING_POP
