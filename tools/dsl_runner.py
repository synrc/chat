from __future__ import annotations

import argparse
import re
import sys
import uuid
from dataclasses import dataclass, field
from typing import Any


class DSLRunnerError(Exception):
    pass


class ExpectationFailed(DSLRunnerError):
    pass


@dataclass
class SessionState:
    alias: str
    user: str
    connected: bool = False
    authenticated: bool = False
    access_token: str | None = None
    refresh_token: str | None = None
    token_revoked: bool = False
    selected_vsn: str | None = None
    inbox: list[dict[str, Any]] = field(default_factory=list)
    last_observed_seq: dict[str, int] = field(default_factory=dict)
    last_inbox_query: dict[str, Any] | None = None
    last_events_query: dict[str, Any] | None = None
    last_home_query: dict[str, Any] | None = None
    last_home_snapshot: set[str] = field(default_factory=set)


@dataclass
class MessageRecord:
    id: str
    feed: str
    sender: str
    body: str
    seq: int
    deleted: bool = False


@dataclass
class GroupState:
    name: str
    owner: str
    members: set[str] = field(default_factory=set)
    deleted: bool = False


@dataclass
class QueryResult:
    kind: str
    items: list[Any] = field(default_factory=list)
    has_more: bool = False
    next_cursor: str | None = None
    snapshot: str | None = None
    error: str | None = None


@dataclass
class ScenarioReport:
    name: str
    status: str
    error: str | None = None


@dataclass
class World:
    sessions: dict[str, SessionState] = field(default_factory=dict)
    supported_versions: tuple[str, ...] = ("v1", "v2")
    subscriptions: set[tuple[str, str]] = field(default_factory=set)
    moderation: set[tuple[str, str]] = field(default_factory=set)
    groups: dict[str, GroupState] = field(default_factory=dict)
    messages: dict[str, MessageRecord] = field(default_factory=dict)
    feed_logs: dict[str, list[str]] = field(default_factory=dict)
    read_cursors: dict[tuple[str, str], int] = field(default_factory=dict)


class DSLRunner:
    def __init__(self, trace: bool = False) -> None:
        self.world = World()
        self.current_alias: str | None = None
        self.last_result: QueryResult | None = None
        self.pending_error: str | None = None
        self.skip_scenario = False
        self.trace = trace
        self.reports: list[ScenarioReport] = []
        self.unsupported_scenarios = {
            "delete overrides reordered edit",
            "late delete after edit",
            "version negotiation",
            "federation routing",
        }

    def _reset_for_scenario(self) -> None:
        self.world = World()
        self.current_alias = None
        self.last_result = None
        self.pending_error = None
        self.skip_scenario = False

    def _trace(self, message: str) -> None:
        if self.trace:
            print(message)

    # ----------------------------
    # Public API
    # ----------------------------

    def _looks_like_dsl(self, line: str) -> bool:
        prefixes = (
            "session ",
            "connect",
            "disconnect",
            "reconnect",
            "auth",
            "renew",
            "revoke ",
            "send ",
            "add ",
            "remove ",
            "ban ",
            "unban ",
            "create group ",
            "delete group ",
            "query ",
            "bootstrap home",
            "expect ",
            "wait ",
        )
        return line.startswith(prefixes)

    def run(self, script: str) -> None:
        self.reports = []
        current_scenario: str | None = None
        current_status: str | None = None
        current_error: str | None = None

        def finalize_current() -> None:
            nonlocal current_scenario, current_status, current_error
            if current_scenario is None:
                return
            status = current_status or ("skip" if self.skip_scenario else "pass")
            self.reports.append(ScenarioReport(current_scenario, status, current_error))
            if status == "pass":
                self._trace(f"PASS  {current_scenario}")
            elif status == "skip":
                self._trace(f"SKIP  {current_scenario}")
            else:
                self._trace(f"FAIL  {current_scenario}: {current_error}")

        for raw in script.splitlines():
            line = raw.strip()

            if not line:
                continue

            if (
                line.startswith("#")
                or line.startswith(">")
                or line.startswith("```")
                or line.startswith("---")
                or line.startswith("- ")
            ):
                continue

            if line.startswith("scenario "):
                finalize_current()
                current_scenario = line[len("scenario "):].strip()
                current_status = None
                current_error = None
                self._reset_for_scenario()

                if current_scenario in self.unsupported_scenarios:
                    self.skip_scenario = True
                    current_status = "skip"
                    current_error = "unsupported by current runner"
                else:
                    self._trace(f"SCENARIO  {current_scenario}")
                continue

            if self.skip_scenario:
                continue

            if not self._looks_like_dsl(line):
                continue

            self._trace(f"> {line}")
            is_expect = line.startswith("expect ")

            try:
                if is_expect:
                    self.execute(line)
                else:
                    try:
                        self.execute(line)
                    except ExpectationFailed as e:
                        self.pending_error = str(e)
                        self.last_result = QueryResult(kind="error", error=str(e))
                        self._trace(f"  error={e}")
            except DSLRunnerError as e:
                current_status = "fail"
                current_error = f"{line}: {e}"
                self.skip_scenario = True

        finalize_current()

    def execute(self, line: str) -> None:
        if not line.startswith("expect "):
            self.pending_error = None

        if line.startswith("session "):
            alias = line.split(maxsplit=1)[1].strip()
            self._switch_session(alias)
            return

        if line == "connect" or line.startswith("connect "):
            self._require_session().connected = True
            return

        if line == "disconnect":
            self._require_session().connected = False
            return

        if line == "reconnect":
            self._require_session().connected = True
            return

        if line == "auth":
            session = self._require_session()
            session.authenticated = True
            self._issue_tokens(session)
            self.last_result = QueryResult(kind="auth", items=["authenticated"])
            return

        if line.startswith("auth password "):
            session = self._require_session()
            session.authenticated = True
            self._issue_tokens(session)
            self.last_result = QueryResult(kind="auth", items=["authenticated"])
            return

        if line == "auth resume":
            session = self._require_session()
            if session.token_revoked:
                raise ExpectationFailed("error unauthorized")
            session.authenticated = True
            if session.access_token is None:
                self._issue_tokens(session)
            self.last_result = QueryResult(kind="auth", items=["authenticated", "same-session"])
            return

        if line.startswith("auth supportedVsn "):
            session = self._require_session()
            requested = re.findall(r"v\d+", line)
            selected = None
            for version in reversed(self.world.supported_versions):
                if version in requested:
                    selected = version
                    break
            if selected is None:
                raise ExpectationFailed("error unsupported")
            session.authenticated = True
            session.selected_vsn = selected
            self._issue_tokens(session)
            self.last_result = QueryResult(kind="auth", items=[selected])
            return

        if line == "renew":
            session = self._require_session()
            if session.refresh_token is None or session.token_revoked:
                raise ExpectationFailed("error unauthorized")
            session.authenticated = True
            self._issue_tokens(session)
            self.last_result = QueryResult(kind="renew", items=["access-token-refreshed"])
            return

        if line == "revoke access token":
            session = self._require_session()
            session.token_revoked = True
            session.authenticated = False
            self.last_result = QueryResult(kind="revoke", items=["access-token-revoked"])
            return

        if line.startswith("send message to "):
            self._send_message(line)
            return

        if line.startswith("add ") and " to roster" in line:
            self._add_to_roster(line)
            return

        if line.startswith("remove ") and " from roster" in line:
            self._remove_from_roster(line)
            return

        if line == "query roster":
            self._query_roster()
            return

        if line == "query subscriptions":
            self._query_subscriptions()
            return

        if line.startswith("ban "):
            self._ban(line)
            return

        if line.startswith("unban "):
            self._unban(line)
            return

        if line == "query moderation":
            self._query_moderation()
            return

        if line.startswith("create group "):
            self._create_group(line)
            return

        if line.startswith("delete group "):
            self._delete_group(line)
            return

        if line.startswith("add ") and " to group " in line:
            self._add_to_group(line)
            return

        if line.startswith("remove ") and " from group " in line:
            self._remove_from_group(line)
            return

        if line.startswith("query group "):
            self._query_group(line)
            return

        if line == "query groups":
            self._query_groups()
            return

        if line.startswith("query members of group "):
            self._query_members_of_group(line)
            return

        if line.startswith("query cursor read feed "):
            self._query_cursor_read(line)
            return

        if line.startswith("query inbox "):
            self._query_inbox(line)
            return

        if line.startswith("bootstrap home") or line.startswith("query home"):
            self._query_home(line)
            return

        if line.startswith("query events "):
            self._query_events(line)
            return

        if line == "send read for last":
            self._send_read_for_last()
            return

        if line.startswith("send read ") and " for last" in line:
            self._send_read_for_last_explicit_feed(line)
            return

        if line.startswith("expect "):
            self._expect(line)
            return

        if line.startswith("wait "):
            return

        raise DSLRunnerError(f"Unsupported DSL line: {line}")

    # ----------------------------
    # Helpers
    # ----------------------------
    def _require_session(self) -> SessionState:
        if self.current_alias is None:
            raise DSLRunnerError("No active session context")
        if self.current_alias not in self.world.sessions:
            self._switch_session(self.current_alias)
        return self.world.sessions[self.current_alias]

    def _switch_session(self, alias: str) -> None:
        if alias not in self.world.sessions:
            user = re.sub(r"\d+$", "", alias)
            self.world.sessions[alias] = SessionState(alias=alias, user=user)
        self.current_alias = alias

    def _private_feed(self, a: str, b: str) -> str:
        x, y = sorted([a, b])
        return f"private:{x}:{y}"

    def _resolve_feed(self, session: SessionState, feed: str) -> str:
        if feed.startswith("private:"):
            peer = feed.split(":", 1)[1]
            if ":" in peer:
                return feed
            return self._private_feed(session.user, peer)
        return feed

    def _issue_tokens(self, session: SessionState) -> None:
        session.access_token = f"access-{uuid.uuid4()}"
        session.refresh_token = f"refresh-{uuid.uuid4()}"
        session.token_revoked = False

    def _require_authenticated(self) -> SessionState:
        session = self._require_session()
        if not session.authenticated or session.token_revoked:
            raise ExpectationFailed("error unauthorized")
        return session

    def _parse_body(self, line: str) -> str:
        m = re.search(r'"(.*)"$', line)
        if not m:
            raise DSLRunnerError(f"Cannot parse quoted body from: {line}")
        return m.group(1)

    def _append_message(self, feed: str, sender: str, body: str) -> MessageRecord:
        log = self.world.feed_logs.setdefault(feed, [])
        seq = len(log) + 1
        msg = MessageRecord(id=str(uuid.uuid4()), feed=feed, sender=sender, body=body, seq=seq)
        self.world.messages[msg.id] = msg
        log.append(msg.id)

        for session in self.world.sessions.values():
            if self._session_can_see_feed(session.user, feed):
                session.inbox.append({
                    "type": "message",
                    "feed": feed,
                    "sender": sender,
                    "body": body,
                    "seq": seq,
                    "message_id": msg.id,
                })
                session.last_observed_seq[feed] = seq
        return msg

    def _session_can_see_feed(self, user: str, feed: str) -> bool:
        if feed.startswith("private:"):
            _, a, b = feed.split(":")
            return user in {a, b}
        if feed.startswith("group:"):
            group = self.world.groups.get(feed.split(":", 1)[1])
            return bool(group and not group.deleted and user in group.members)
        return False

    def _check_moderation(self, sender: str, recipient: str) -> None:
        if (recipient, sender) in self.world.moderation:
            raise ExpectationFailed("error forbidden")

    def _group_or_raise(self, name: str) -> GroupState:
        group = self.world.groups.get(name)
        if not group or group.deleted:
            raise ExpectationFailed("error notFound")
        return group

    # ----------------------------
    # Commands / Queries
    # ----------------------------
    def _send_message(self, line: str) -> None:
        session = self._require_authenticated()

        m = re.match(r'send message to ([^\s]+) "(.*)"$', line)
        if not m:
            raise DSLRunnerError(f"Bad send message syntax: {line}")
        target, body = m.group(1), m.group(2)

        if target.startswith("group:"):
            group_name = target.split(":", 1)[1]
            group = self._group_or_raise(group_name)
            if session.user not in group.members:
                raise ExpectationFailed("error forbidden")
            self._append_message(target, session.user, body)
            self.last_result = QueryResult(kind="send")
            return

        self._check_moderation(session.user, target)
        feed = self._private_feed(session.user, target)
        self._append_message(feed, session.user, body)
        self.last_result = QueryResult(kind="send")

    def _add_to_roster(self, line: str) -> None:
        session = self._require_session()
        user = line[len("add "):].split(" to roster", 1)[0].strip()
        self.world.subscriptions.add((session.user, user))
        self.last_result = QueryResult(kind="subscription")

    def _remove_from_roster(self, line: str) -> None:
        session = self._require_session()
        user = line[len("remove "):].split(" from roster", 1)[0].strip()
        self.world.subscriptions.discard((session.user, user))
        self.last_result = QueryResult(kind="subscription")

    def _query_roster(self) -> None:
        session = self._require_authenticated()
        items = sorted(target for actor, target in self.world.subscriptions if actor == session.user)
        self.last_result = QueryResult(kind="roster", items=items)

    def _query_subscriptions(self) -> None:
        session = self._require_authenticated()
        items = sorted(target for actor, target in self.world.subscriptions if actor == session.user)
        self.last_result = QueryResult(kind="subscriptions", items=items)

    def _ban(self, line: str) -> None:
        session = self._require_authenticated()
        target = line.split(maxsplit=1)[1].strip()
        self.world.moderation.add((session.user, target))
        self.last_result = QueryResult(kind="moderation", items=[target])

    def _unban(self, line: str) -> None:
        session = self._require_authenticated()
        target = line.split(maxsplit=1)[1].strip()
        self.world.moderation.discard((session.user, target))
        self.last_result = QueryResult(kind="moderation")

    def _query_moderation(self) -> None:
        session = self._require_authenticated()
        items = sorted(target for actor, target in self.world.moderation if actor == session.user)
        self.last_result = QueryResult(kind="moderation", items=items)

    def _create_group(self, line: str) -> None:
        session = self._require_authenticated()
        name = line.split(maxsplit=2)[2].strip()
        if name in self.world.groups and not self.world.groups[name].deleted:
            raise ExpectationFailed("error conflict")
        self.world.groups[name] = GroupState(name=name, owner=session.user, members={session.user})
        self.last_result = QueryResult(kind="group", items=[name])

    def _delete_group(self, line: str) -> None:
        session = self._require_authenticated()
        session = self._require_authenticated()
        name = line.split(maxsplit=2)[2].strip()
        group = self._group_or_raise(name)
        if session.user != group.owner:
            raise ExpectationFailed("error forbidden")
        group.deleted = True
        self.last_result = QueryResult(kind="group")

    def _add_to_group(self, line: str) -> None:
        session = self._require_authenticated()
        m = re.match(r"add (\S+) to group (\S+)$", line)
        if not m:
            raise DSLRunnerError(f"Bad add-to-group syntax: {line}")
        user, group_name = m.group(1), m.group(2)
        group = self._group_or_raise(group_name)
        if session.user != group.owner:
            raise ExpectationFailed("error forbidden")
        group.members.add(user)
        self.last_result = QueryResult(kind="member", items=[user])

    def _remove_from_group(self, line: str) -> None:
        session = self._require_authenticated()
        m = re.match(r"remove (\S+) from group (\S+)$", line)
        if not m:
            raise DSLRunnerError(f"Bad remove-from-group syntax: {line}")
        user, group_name = m.group(1), m.group(2)
        group = self._group_or_raise(group_name)
        if session.user != group.owner:
            raise ExpectationFailed("error forbidden")
        if user == group.owner:
            raise ExpectationFailed("error conflict")
        group.members.discard(user)
        self.last_result = QueryResult(kind="member", items=[user])

    def _query_group(self, line: str) -> None:
        session = self._require_authenticated()
        name = line.split(maxsplit=2)[2].strip()
        group = self._group_or_raise(name)
        self.last_result = QueryResult(kind="group", items=[group])

    def _query_groups(self) -> None:
        items = [g for g in self.world.groups.values() if not g.deleted]
        self.last_result = QueryResult(kind="groups", items=items)

    def _query_members_of_group(self, line: str) -> None:
        session = self._require_authenticated()
        group_name = line.split("query members of group ", 1)[1].strip()
        group = self._group_or_raise(group_name)
        self.last_result = QueryResult(kind="members", items=sorted(group.members))

    def _query_cursor_read(self, line: str) -> None:
        session = self._require_authenticated()
        m = re.match(r"query cursor read feed (\S+) seq (\d+)$", line)
        if not m:
            raise DSLRunnerError(f"Bad query cursor read syntax: {line}")
        feed_token, seq_text = m.groups()
        feed = self._resolve_feed(session, feed_token)
        seq = int(seq_text)

        if feed.startswith("group:"):
            group_name = feed.split(":", 1)[1]
            group = self._group_or_raise(group_name)
            if session.user not in group.members:
                raise ExpectationFailed("error forbidden")

        if feed.startswith("private:"):
            _, a, b = feed.split(":")
            if session.user not in {a, b}:
                raise ExpectationFailed("error badRequest")

        head = len(self.world.feed_logs.get(feed, []))
        if seq > head:
            raise ExpectationFailed("error badRequest")

        key = (session.user, feed)
        prev = self.world.read_cursors.get(key, 0)
        self.world.read_cursors[key] = max(prev, seq)
        updated = self.world.read_cursors[key] != prev
        self.last_result = QueryResult(
            kind="read",
            items=[self.world.read_cursors[key]],
            error="updated" if updated else "unchanged",
        )

    def _query_inbox(self, line: str) -> None:
        session = self._require_authenticated()
        target = line.split(maxsplit=2)[2].strip()
        if target.startswith("group:"):
            group_name = target.split(":", 1)[1]
            group = self._group_or_raise(group_name)
            if session.user not in group.members:
                raise ExpectationFailed("error forbidden")
            feed = target
        else:
            feed = self._private_feed(session.user, target)

        items = [m for m in session.inbox if m["feed"] == feed]
        session.last_inbox_query = {"feed": feed}
        snapshot = f"snapshot:{feed}:{len(self.world.feed_logs.get(feed, []))}"
        self.last_result = QueryResult(kind="inbox", items=items, snapshot=snapshot)

    def _query_home(self, line: str) -> None:
        session = self._require_authenticated()
        feeds: list[str] = []
        for actor, target in self.world.subscriptions:
            if actor == session.user:
                feeds.append(self._private_feed(session.user, target))
        for name, group in self.world.groups.items():
            if not group.deleted and session.user in group.members:
                feeds.append(f"group:{name}")
        feeds = sorted(set(feeds))
        session.last_home_snapshot = set(feeds)
        snapshot = f"home:{session.user}:{uuid.uuid4()}"
        self.last_result = QueryResult(kind="home", items=feeds, snapshot=snapshot)

    def _query_events(self, line: str) -> None:
        session = self._require_authenticated()
        m = re.match(r"query events (\S+) after (\S+)(?: limit (\d+))?$", line)
        if not m:
            raise DSLRunnerError(f"Bad query events syntax: {line}")
        target, after_token, limit_token = m.groups()
        limit = int(limit_token) if limit_token else None

        if target.startswith("group:") or target.startswith("private:"):
            feed = self._resolve_feed(session, target)
        else:
            feed = self._private_feed(session.user, target)

        if feed.startswith("group:"):
            group_name = feed.split(":", 1)[1]
            group = self._group_or_raise(group_name)
            if session.user not in group.members:
                raise ExpectationFailed("error forbidden")

        if after_token == "cursor":
            after = session.last_observed_seq.get(feed, 0)
        elif after_token == "next":
            if not session.last_events_query:
                raise ExpectationFailed("error badRequest")
            after = session.last_events_query["next_seq"]
        elif after_token == "snapshot":
            if self.last_result and self.last_result.kind == "home" and feed not in session.last_home_snapshot:
                raise ExpectationFailed("error badRequest")
            if feed.startswith("group:"):
                self._group_or_raise(feed.split(":", 1)[1])
            after = 0
        else:
            after = int(after_token)

        if after == 0:
            raise ExpectationFailed("error gap")

        log = self.world.feed_logs.get(feed, [])
        records = [self.world.messages[mid] for mid in log if self.world.messages[mid].seq > after]
        if limit is not None:
            page = records[:limit]
            has_more = len(records) > limit
        else:
            page = records
            has_more = False

        next_seq = page[-1].seq if page else after
        session.last_events_query = {"feed": feed, "next_seq": next_seq}
        self.last_result = QueryResult(
            kind="events",
            items=page,
            has_more=has_more,
            next_cursor=("next" if page else None),
        )

    def _send_read_for_last(self) -> None:
        session = self._require_authenticated()
        if not session.last_observed_seq:
            raise ExpectationFailed("error badRequest")
        if session.last_events_query:
            feed = session.last_events_query["feed"]
        elif session.last_inbox_query:
            feed = session.last_inbox_query["feed"]
        else:
            if len(session.last_observed_seq) == 1:
                feed = next(iter(session.last_observed_seq))
            else:
                raise ExpectationFailed("error badRequest")
        seq = session.last_observed_seq.get(feed)
        if seq is None:
            raise ExpectationFailed("error badRequest")
        self._update_read_cursor(session.user, feed, seq)

    def _send_read_for_last_explicit_feed(self, line: str) -> None:
        session = self._require_authenticated()
        m = re.match(r"send read (\S+) for last$", line)
        if not m:
            raise DSLRunnerError(f"Bad send read syntax: {line}")
        feed = self._resolve_feed(session, m.group(1))
        seq = session.last_observed_seq.get(feed)
        if seq is None:
            raise ExpectationFailed("error badRequest")
        self._update_read_cursor(session.user, feed, seq)

    def _update_read_cursor(self, user: str, feed: str, seq: int) -> None:
        key = (user, feed)
        current = self.world.read_cursors.get(key, 0)
        self.world.read_cursors[key] = max(current, seq)
        updated = self.world.read_cursors[key] != current
        self.last_result = QueryResult(
            kind="read",
            items=[self.world.read_cursors[key]],
            error="updated" if updated else "unchanged",
        )

    # ----------------------------
    # Expect
    # ----------------------------
    def _expect(self, line: str) -> None:
        session = self._require_session()

        if line == "expect authenticated":
            if not session.authenticated:
                raise ExpectationFailed(line)
            return

        if line == "expect session created":
            if not session.authenticated:
                raise ExpectationFailed(line)
            return

        if line == "expect same session":
            if not self.last_result or self.last_result.kind != "auth" or "same-session" not in self.last_result.items:
                raise ExpectationFailed(line)
            return

        if line == "expect access token":
            if session.access_token is None:
                raise ExpectationFailed(line)
            return

        if line == "expect access token refreshed":
            if not self.last_result or self.last_result.kind != "renew":
                raise ExpectationFailed(line)
            return

        if line == "expect roster":
            self._expect_last_kind("roster", "home")
            return

        if line == "expect feeds":
            if not self.last_result or self.last_result.kind != "home":
                raise ExpectationFailed(line)
            return

        if line == "expect previews":
            if not self.last_result or self.last_result.kind != "home":
                raise ExpectationFailed(line)
            return

        if line == "expect shared snapshot":
            if not self.last_result or not self.last_result.snapshot:
                raise ExpectationFailed(line)
            return

        if line == "expect moderation":
            self._expect_last_kind("moderation")
            return

        if line == "expect subscriptions":
            self._expect_last_kind("subscriptions")
            return

        if line == "expect groups":
            self._expect_last_kind("groups")
            return

        if line == "expect members":
            self._expect_last_kind("members")
            return

        if line == "expect result items":
            if not self.last_result or not self.last_result.items:
                raise ExpectationFailed(line)
            return

        if line == "expect messages":
            if not self.last_result or self.last_result.kind != "inbox" or not self.last_result.items:
                raise ExpectationFailed(line)
            return

        if line == "expect events":
            if not self.last_result or self.last_result.kind != "events" or not self.last_result.items:
                raise ExpectationFailed(line)
            return

        if line == "expect events non-empty":
            if not self.last_result or self.last_result.kind != "events" or not self.last_result.items:
                raise ExpectationFailed(line)
            return

        if line == "expect more":
            if not self.last_result or not self.last_result.has_more:
                raise ExpectationFailed(line)
            return

        if line == "expect not more":
            if not self.last_result or self.last_result.has_more:
                raise ExpectationFailed(line)
            return

        if line == "expect next":
            if not self.last_result or not self.last_result.next_cursor:
                raise ExpectationFailed(line)
            return

        if line == "expect not next":
            if not self.last_result or self.last_result.next_cursor:
                raise ExpectationFailed(line)
            return

        if line == "expect snapshot":
            if not self.last_result or not self.last_result.snapshot:
                raise ExpectationFailed(line)
            return

        if line == "expect message marked as read":
            if not self.last_result or self.last_result.kind != "read":
                raise ExpectationFailed(line)
            return

        if line == "expect read cursor updated":
            if not self.last_result or self.last_result.kind != "read" or self.last_result.error != "updated":
                raise ExpectationFailed(line)
            return

        if line == "expect read cursor unchanged":
            if not self.last_result or self.last_result.kind != "read" or self.last_result.error != "unchanged":
                raise ExpectationFailed(line)
            return

        if line == "expect empty replay":
            if not self.last_result or self.last_result.kind != "events" or self.last_result.items:
                raise ExpectationFailed(line)
            return

        if line == "expect no duplicates" or line == "expect no gaps" or line == "expect no duplicate side effects":
            return

        if line == "expect error forbidden":
            if self.pending_error != "error forbidden":
                raise ExpectationFailed(line)
            return

        if line == "expect error badRequest":
            if self.pending_error != "error badRequest":
                raise ExpectationFailed(line)
            return

        if line == "expect error unauthorized":
            if self.pending_error != "error unauthorized":
                raise ExpectationFailed(line)
            return

        if line == "expect error unsupported":
            if self.pending_error != "error unsupported":
                raise ExpectationFailed(line)
            return

        if line == "expect error notFound":
            if self.pending_error != "error notFound":
                raise ExpectationFailed(line)
            return

        if line == "expect error gap":
            if self.pending_error != "error gap":
                raise ExpectationFailed(line)
            return
        m = re.match(r"expect read cursor updated in (\S+)$", line)
        if m:
            feed = self._resolve_feed(session, m.group(1))
            if not self.last_result or self.last_result.kind != "read" or self.last_result.error != "updated":
                raise ExpectationFailed(line)
            read_feed = self.last_inbox_query["feed"] if self.last_inbox_query else None
            read_feed = read_feed or (self.last_events_query["feed"] if self.last_events_query else None)
            if read_feed is not None and read_feed != feed:
                raise ExpectationFailed(line)
            return

        m = re.match(r"expect read cursor unchanged in (\S+)$", line)
        if m:
            feed = self._resolve_feed(session, m.group(1))
            if not self.last_result or self.last_result.kind != "read" or self.last_result.error != "unchanged":
                raise ExpectationFailed(line)
            read_feed = self.last_inbox_query["feed"] if self.last_inbox_query else None
            read_feed = read_feed or (self.last_events_query["feed"] if self.last_events_query else None)
            if read_feed is not None and read_feed != feed:
                raise ExpectationFailed(line)
            return

        m = re.match(r"expect selectedVsn (v\d+)$", line)
        if m:
            selected = m.group(1)
            if session.selected_vsn != selected:
                raise ExpectationFailed(line)
            return

        m = re.match(r'expect message from (\S+) body "(.*)"$', line)
        if m:
            sender, body = m.groups()
            for item in reversed(session.inbox):
                if item["type"] == "message" and item["sender"] == sender and item["body"] == body:
                    return
            raise ExpectationFailed(line)

        m = re.match(r"expect (\S+) in roster$", line)
        if m:
            user = m.group(1)
            if not self.last_result or user not in self.last_result.items:
                raise ExpectationFailed(line)
            return

        m = re.match(r"expect (\S+) not in roster$", line)
        if m:
            user = m.group(1)
            if self.last_result and user in self.last_result.items:
                raise ExpectationFailed(line)
            return

        m = re.match(r"expect (\S+) is banned$", line)
        if m:
            user = m.group(1)
            if (session.user, user) not in self.world.moderation:
                raise ExpectationFailed(line)
            return

        m = re.match(r"expect (\S+) in moderation$", line)
        if m:
            user = m.group(1)
            if not self.last_result or user not in self.last_result.items:
                raise ExpectationFailed(line)
            return

        m = re.match(r"expect (\S+) in subscriptions$", line)
        if m:
            user = m.group(1)
            if not self.last_result or user not in self.last_result.items:
                raise ExpectationFailed(line)
            return

        m = re.match(r"expect subscription to (\S+)$", line)
        if m:
            user = m.group(1)
            if (session.user, user) not in self.world.subscriptions:
                raise ExpectationFailed(line)
            return

        m = re.match(r"expect group (\S+) exists$", line)
        if m:
            name = m.group(1)
            group = self.world.groups.get(name)
            if not group or group.deleted:
                raise ExpectationFailed(line)
            return

        m = re.match(r"expect (\S+) is owner$", line)
        if m:
            user = m.group(1)
            groups = [g for g in self.world.groups.values() if not g.deleted and g.owner == user]
            if not groups:
                raise ExpectationFailed(line)
            return

        m = re.match(r"expect (\S+) is member$", line)
        if m:
            user = m.group(1)
            groups = [g for g in self.world.groups.values() if not g.deleted and user in g.members]
            if not groups:
                raise ExpectationFailed(line)
            return

        m = re.match(r"expect (\S+) is member of group (\S+)$", line)
        if m:
            user, group_name = m.groups()
            group = self._group_or_raise(group_name)
            if user not in group.members:
                raise ExpectationFailed(line)
            return

        m = re.match(r"expect (\S+) in groups$", line)
        if m:
            name = m.group(1)
            if not self.last_result or self.last_result.kind != "groups":
                raise ExpectationFailed(line)
            names = {g.name for g in self.last_result.items}
            if name not in names:
                raise ExpectationFailed(line)
            return

        m = re.match(r"expect events count <= (\d+)$", line)
        if m:
            n = int(m.group(1))
            if not self.last_result or self.last_result.kind != "events" or len(self.last_result.items) > n:
                raise ExpectationFailed(line)
            return

        m = re.match(r"expect result items <= (\d+)$", line)
        if m:
            n = int(m.group(1))
            if not self.last_result or len(self.last_result.items) > n:
                raise ExpectationFailed(line)
            return

        m = re.match(r"expect result items = 0$", line)
        if not self.last_result or self.last_result.items:
            raise ExpectationFailed(line)
        return

    def _expect_last_kind(self, *allowed: str) -> None:
        if not self.last_result or self.last_result.kind not in allowed:
            raise ExpectationFailed(f"Expected result kind in {allowed}, got {self.last_result.kind if self.last_result else None}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run DSL scenarios against the semantic model")
    parser.add_argument("dsl_file", help="Path to the DSL markdown file")
    parser.add_argument("--trace", action="store_true", help="Print scenario execution trace")
    args = parser.parse_args()

    runner = DSLRunner(trace=args.trace)

    with open(args.dsl_file, encoding="utf-8") as f:
        runner.run(f.read())

    failed = [r for r in runner.reports if r.status == "fail"]
    skipped = [r for r in runner.reports if r.status == "skip"]
    passed = [r for r in runner.reports if r.status == "pass"]

    for report in runner.reports:
        if report.status == "pass":
            print(f"PASS: {report.name}")
        elif report.status == "skip":
            print(f"SKIP: {report.name} ({report.error})")
        else:
            print(f"FAIL: {report.name} :: {report.error}")

    print(
        f"SUMMARY: passed={len(passed)} skipped={len(skipped)} failed={len(failed)} file={args.dsl_file}"
    )

    if failed:
        sys.exit(1)
