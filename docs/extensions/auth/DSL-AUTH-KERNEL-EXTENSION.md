# DSL-AUTH-KERNEL-EXTENSION

Typed auth/session extension поверх semantic kernel

## Навіщо це потрібно

Цей документ фіксує auth/session extension поверх typed semantic kernel DSL.

Його мета:
- не змішувати protocol semantics і auth semantics;
- показати, як `Authority` / session layer вбудовується поверх core kernel;
- зафіксувати, які нові facts, actions, observations і judgments потрібні;
- відокремити authentication від authorization;
- відокремити session lifecycle від transport connection lifecycle.

Це не заміна core kernel.
Це typed extension над ним.

---

## Базовий принцип

AUTH extension:

- не змінює `Message/Event/Replay/View` semantics;
- не переписує canonical message state;
- не змінює feed ordering;
- не змінює read cursor як canonical truth;
- визначає:
  - хто authenticated;
  - яка session створена / відновлена;
  - які credentials валідні;
  - чи дозволено виконувати protected action без `unauthorized`.

Тобто AUTH живе поверх:

- `action`
- `observation`
- `predicate`
- `judgment`

із typed kernel, але не замінює їх.

---

## Які core distinction-и зберігаються

AUTH extension зберігає базові distinction-и typed kernel:

- `session ≠ connection`
- `session ≠ principal`
- `read cursor ≠ session replay position`
- `permission ≠ authentication`
- `View ≠ state ≠ event`

AUTH extension лише уточнює:

- `WellFormedAction`
- `Permits`
- `Produces`
- `Satisfies`

для auth/session-related interaction.

---

## Typed extension

```ocaml
module AuthExt = struct
  open Kernel

  (* ---------- auth/session tokens ---------- *)

  type access_token = AccessToken of string
  type refresh_token = RefreshToken of string
  type auth_vsn = AuthVsn of string
  type device_id = DeviceId of string

  (* ---------- authority/session state ---------- *)

  type session_status =
    | Active
    | Expired
    | Revoked

  type auth_fact =
    | SessionExists of {
        session : session_id;
        principal : principal;
        device : device_id option;
        status : session_status;
      }
    | SessionBoundAccessToken of {
        session : session_id;
        token : access_token;
      }
    | DeviceBoundRefreshToken of {
        principal : principal;
        device : device_id option;
        token : refresh_token;
      }
    | SupportedAuthVersion of auth_vsn
    | SelectedAuthVersion of auth_vsn
    | AuthenticatedPrincipal of {
        session : session_id;
        principal : principal;
      }

  (* ---------- authority actions ---------- *)

  type auth_request =
    | Authenticate of {
        supported_vsn : auth_vsn list option;
      }
    | Resume of {
        access_token : access_token option;
      }
    | Renew of {
        refresh_token : refresh_token option;
      }
    | RevokeAccessToken
    | RevokeRefreshToken

  type auth_action =
    | AuthorityAction of {
        session : session_id;
        principal : principal;
        request : auth_request;
      }

  (* ---------- authority observations ---------- *)

  type auth_observation =
    | Authenticated of {
        session : session_id;
        principal : principal;
      }
    | SessionCreated of {
        session : session_id;
      }
    | SameSession of {
        session : session_id;
      }
    | AccessTokenIssued of {
        session : session_id;
        token : access_token;
      }
    | AccessTokenRefreshed of {
        session : session_id;
        token : access_token;
      }
    | Unauthorized
    | Unsupported

  (* ---------- auth predicates ---------- *)

  type auth_predicate =
    | IsAuthenticated
    | HasSession
    | SameSessionAsBefore
    | HasAccessToken
    | AccessTokenRefreshedPred
    | UnauthorizedPred
    | UnsupportedPred

  (* ---------- auth judgments ---------- *)

  type auth_judgment =
    | AuthStateHas of state * auth_fact
    | PerformsAuth of state * auth_action * state
    | ProducesAuth of state * auth_action * auth_observation
    | SatisfiesAuth of state * auth_predicate
end
```

---

## Що тут є новим primitive

### 1. `auth_fact`

Це facts не про protocol truth, а про authority/session state.

Наприклад:
- чи існує session;
- кому вона належить;
- який у неї статус;
- який access token прив'язаний до session;
- який refresh token прив'язаний до device;
- яка auth version підтримується або вибрана.

Ці facts не є message/event facts.
Вони є умовами для auth/session lifecycle.

### 2. `auth_action`

AUTH краще тримати окремо від core `SessionOp`, бо:

- `connect/disconnect` — це transport/runtime coordination;
- `authenticate/resume/renew/revoke` — це authority/session semantics.

Тому:
- `SessionOp` лишається в core kernel;
- `AuthorityAction` живе в auth extension.

### 3. `auth_observation`

AUTH повинен уміти віддавати не лише `error unauthorized`,
а й success-oriented observations:

- authenticated
- session created
- same session
- access token
- access token refreshed
- unsupported

Це прямо відповідає поточному `DSL-AUTH.md`.

### 4. `auth_judgment`

AUTH повинен мати свої judgments, а не лише користуватись core `Permits`.

Причина проста:
- створення session;
- відновлення session;
- перевидача access token;
- revoke;

це окремі semantic relation-и, не тотожні protocol transition model.

---

## Як AUTH extension чіпляється до core kernel

### 1. AUTH уточнює `Permits`

Core kernel already має:

```ocaml
Permits of state * action * permission
```

AUTH extension визначає, коли protected action permitted, а коли ні.

Наприклад:
- replay без auth -> unauthorized;
- renew після reconnect -> protected query знову allowed;
- resume після revoked token -> unauthorized.

Тобто:
- core kernel містить форму `permission`;
- AUTH extension визначає precondition-и для access до protected actions.

### 2. AUTH не переписує `Steps`

AUTH може створювати або оновлювати session-related state,
але не повинен переписувати message/event truth.

Наприклад:
- revoked access token не змінює protocol history;
- invalid auth context не затирає message state.

Це прямо зафіксовано у `DSL-AUTH.md`.

---

## Surface-to-extension elaboration

Surface AUTH forms не переходять напряму в core kernel.
Вони elaborates у `auth_action` / `auth_predicate`.

### Authenticate

```text
auth
```

elaborates у:

```ocaml
AuthorityAction {
  session = SessionId "...";
  principal = Principal "...";
  request = Authenticate {
    supported_vsn = None;
  };
}
```

### Authenticate with supported versions

```text
auth supportedVsn [v3]
```

elaborates у:

```ocaml
AuthorityAction {
  session = SessionId "...";
  principal = Principal "...";
  request = Authenticate {
    supported_vsn = Some [AuthVsn "v3"];
  };
}
```

### Resume

```text
auth resume
```

elaborates у:

```ocaml
AuthorityAction {
  session = SessionId "...";
  principal = Principal "...";
  request = Resume {
    access_token = None;  (* restored from auth context / session env *)
  };
}
```

### Renew

```text
renew
```

elaborates у:

```ocaml
AuthorityAction {
  session = SessionId "...";
  principal = Principal "...";
  request = Renew {
    refresh_token = None;  (* restored from auth context / device env *)
  };
}
```

### Revoke

```text
revoke access token
```

elaborates у:

```ocaml
AuthorityAction {
  session = SessionId "...";
  principal = Principal "...";
  request = RevokeAccessToken;
}
```

---

## Expect-level elaboration

Surface AUTH expectations не повинні напряму зливатися з core `predicate`.

Краще мислити так:

- `expect authenticated` -> auth predicate
- `expect session created` -> auth predicate
- `expect same session` -> auth predicate
- `expect access token` -> auth predicate
- `expect access token refreshed` -> auth predicate
- `expect error unauthorized` -> auth predicate
- `expect error unsupported` -> auth predicate

### Auth expectations

```text
expect authenticated
expect session created
expect same session
expect access token
expect access token refreshed
expect error unauthorized
expect error unsupported
```

elaborates у:

```ocaml
IsAuthenticated
HasSession
SameSessionAsBefore
HasAccessToken
AccessTokenRefreshedPred
UnauthorizedPred
UnsupportedPred
```

---

## Operational auth sketch

Позначення:

- Σ — core state
- A — auth/session state
- a — auth action
- o — auth observation

### AUTHENTICATE

supported(request) = true
fresh_session() = s
fresh_access_token() = t

──────────────────────────────────────── AUTH-CREATE
(Σ, A) ⊢ AuthorityAction(session, principal, Authenticate req)
⇝ A + SessionExists(session = s, principal = principal, status = Active)
     + SessionBoundAccessToken(session = s, token = t)

──────────────────────────────────────── AUTH-CREATE-OBS
(Σ, A) ⊢ AuthorityAction(session, principal, Authenticate req)
⇓ Authenticated(session = s, principal = principal)

### AUTHENTICATE-SESSION-CREATED

──────────────────────────────────────── AUTH-SESSION-CREATED
(Σ, A) ⊢ AuthorityAction(session, principal, Authenticate req)
⇓ SessionCreated(session = session)

### AUTHENTICATE-TOKEN

fresh_access_token() = t

──────────────────────────────────────── AUTH-TOKEN
(Σ, A) ⊢ AuthorityAction(session, principal, Authenticate req)
⇓ AccessTokenIssued(session = session, token = t)

### RESUME

SessionExists(session = s, principal = p, status = Active) ∈ A
SessionBoundAccessToken(session = s, token = t) ∈ A
valid_resume_context(s, t)

──────────────────────────────────────── AUTH-RESUME
(Σ, A) ⊢ AuthorityAction(session, principal, Resume ctx) ⇝ A

──────────────────────────────────────── AUTH-RESUME-OBS
(Σ, A) ⊢ AuthorityAction(session, principal, Resume ctx)
⇓ SameSession(session = s)

### RENEW

DeviceBoundRefreshToken(principal = p, device = d, token = rt) ∈ A
fresh_access_token() = at

──────────────────────────────────────── AUTH-RENEW
(Σ, A) ⊢ AuthorityAction(session, principal, Renew ctx)
⇝ A[SessionBoundAccessToken(session = session, token = _) := SessionBoundAccessToken(session = session, token = at)]

──────────────────────────────────────── AUTH-RENEW-OBS
(Σ, A) ⊢ AuthorityAction(session, principal, Renew ctx)
⇓ AccessTokenRefreshed(session = session, token = at)

### REVOKE ACCESS TOKEN

SessionBoundAccessToken(session = s, token = t) ∈ A

──────────────────────────────────────── AUTH-REVOKE-ACCESS
(Σ, A) ⊢ AuthorityAction(session, principal, RevokeAccessToken)
⇝ A[SessionExists(session = s, principal = principal, status = Active) := SessionExists(session = s, principal = principal, status = Revoked)]

### UNAUTHORIZED

missing_or_invalid_auth_context(action)

──────────────────────────────────────── AUTH-UNAUTHORIZED
(Σ, A) ⊢ protected_action ⇓ Unauthorized

### UNSUPPORTED

supported_vsn(request) ∩ server_supported_vsn = ∅

──────────────────────────────────────── AUTH-UNSUPPORTED
(Σ, A) ⊢ AuthorityAction(session, principal, Authenticate req)
⇓ Unsupported

---

## Важливі інваріанти AUTH layer

У цьому extension слід явно зафіксувати такі правила:

1. `authenticate` створює session
2. `resume` не створює нову session
3. `renew` не створює нову session
4. `revoke access token` ламає auth context, але не змінює protocol history
5. reconnect сам по собі не дорівнює втраті session
6. protected query/action без auth дає `unauthorized`
7. session і read cursor — різні області
8. read cursor після resume зберігає ту саму user-scoped semantics
9. `same session` є observation про identity session, а не про connection

---

## Що не входить у цей extension

Свідомо не входить:

- повний PKI handshake;
- parsing X.509 / CMS payload;
- full external IAM implementation;
- enrollment / registration authority;
- federation trust exchange;
- external device inventory;
- full token introspection protocol.

---

## Практичний сенс

Цей extension потрібен для того, щоб:

- AUTH сценарії не жили лише як prose examples;
- `authenticate/resume/renew/revoke` були формалізовані;
- runner з часом міг мати окрему auth/session evaluation phase;
- AUTH не змішувався з ABAC і не вбудовувався в core message semantics.

---

## Головний інваріант extension layer

AUTH extension не повинен:

- переписувати canonical protocol truth;
- трактувати session як connection;
- трактувати revoke як protocol mutation;
- змішувати authentication і authorization.

AUTH повинен лише:
- визначати auth/session context;
- керувати token/session lifecycle;
- давати precondition для protected protocol actions;
- породжувати auth observations для DSL scenarios.
