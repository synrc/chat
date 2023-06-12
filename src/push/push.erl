-module(push).
-export([notify/3, notify/5]).

notify(MessageTitle, MessageBody, DeviceId) -> android:notify(MessageTitle, MessageBody, DeviceId).
notify(Alert, Custom, Type, DeviceId, SessionSettings) -> ios:notify(Alert, Custom, Type, DeviceId, SessionSettings).
