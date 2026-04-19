//
//  Shortcut.c
//  thething
//
//  Created by rdjpower on 4/6/26.
//

#include "Shortcut.h"
#include <Carbon/Carbon.h>

extern void RecordKeyCode_Swift(void);
extern void StopRecordKeyCode_Swift(void);

OSStatus callback(EventHandlerCallRef _r, EventRef event, void* _d) {
    EventHotKeyID id;
    GetEventParameter(event, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(id), NULL, &id);
    
    switch (id.id) {
        case 1:
            RecordKeyCode_Swift();
            break;
        case 2:
            StopRecordKeyCode_Swift();
            break;
    }
    
    return noErr;
}

EventHotKeyRef rkr;
EventHotKeyRef strkr;

void RecordKeyCode_init(void) {
    EventHotKeyID id;
    EventTypeSpec spec;
    
    spec.eventClass = kEventClassKeyboard;
    spec.eventKind = kEventHotKeyPressed;
    
    InstallApplicationEventHandler(&callback, 1, &spec, NULL, NULL);
    
    id.signature = 'rkc1';
    id.id = 1;
    
    RegisterEventHotKey(15, cmdKey, id, GetApplicationEventTarget(), 0, &rkr);
}

void RecordKeyCode_deinit(void) {
    UnregisterEventHotKey(rkr);
}

void StopRecordKeyCode_init(void) {
    EventHotKeyID id;
    EventTypeSpec spec;
    
    spec.eventClass = kEventClassKeyboard;
    spec.eventKind = kEventHotKeyPressed;
    
    InstallApplicationEventHandler(&callback, 1, &spec, NULL, NULL);
    
    id.signature = 'rkc2';
    id.id = 2;
    
    RegisterEventHotKey(15, cmdKey + shiftKey, id, GetApplicationEventTarget(), 0, &rkr);
}

void StopRecordKeyCode_deinit(void) {
    UnregisterEventHotKey(strkr);
}
