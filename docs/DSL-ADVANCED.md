> See DSL-CORE.md for language definition
## Scenario 10. Version

```
scenario version negotiation

session alice
connect

auth supportedVsn [v1, v2]

expect selectedVsn v2
```

---

## Scenario 11. Federation

```
scenario federation routing

session alice
connect brokerA
auth

send message to bob@brokerB "hi"

session bob
connect brokerB
auth

expect message from alice body "hi"
```

---