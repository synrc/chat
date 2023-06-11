-module(push).
-export([description/0, notify/3, notify/5]).
-compile(export_all).

notify(MessageTitle, MessageBody, DeviceId) -> android:notify(MessageTitle, MessageBody, DeviceId).
notify(Alert, Custom, Type, DeviceId, SessionSettings) -> ios:notify(Alert, Custom, Type, DeviceId, SessionSettings).
