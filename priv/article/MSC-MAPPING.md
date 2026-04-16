# MSC-MAPPING.md

## 1. Мета

Цей документ визначає канонічну відповідність між DSL сценаріями та MSC (Z.120) поданням.
Його призначення — слугувати єдиним джерелом істини для автоматичного портування сценаріїв.

---

## 2. Базові правила портування

- session → instance
- given → Preconditions (не message flow)
- send / query → message/action
- expect → condition
- MSC core використовується максимально
- Усі відсутні можливості оформлюються як extension predicates

---

## 3. Таблиця відповідності

### Контекст

| DSL | MSC |
|-----|-----|
| session alice | instance Alice |
| session bob | instance Bob |
| scenario name | msc name |

### Початковий стан

| DSL | MSC |
|-----|-----|
| given ... | Preconditions block |
| group exists | state assumption |
| membership | state assumption |
| read cursor | state assumption |

### Дії

| DSL | MSC |
|-----|-----|
| send message | message arrow |
| query | request message |
| edit/delete | action message |

### Expect

| DSL | MSC |
|-----|-----|
| expect message | condition Seen(...) |
| expect event | condition Seen(...) |
| expect error | condition Error(...) |
| expect more | condition HasMore |
| expect snapshot | condition HasSnapshot |

---

## 4. Extension Predicates

- Seen(x) — спостереження події або повідомлення
- NoGaps — відсутність пропусків у стрімі
- NoDuplicates — відсутність дублікатів
- FinalState(x, state) — фінальний стан
- Visible(x) / Hidden(x) — видимість
- Permitted(action) / Forbidden(action) — доступ
- HasFeature(x) — наявність можливості

---

## 5. Канонічні шаблони

### Message Delivery
Alice → Server → Bob  
condition Seen(Message)

### Replay
Query → Loop(events)  
condition NoGaps  
condition NoDuplicates

### Read
Action → Event  
condition Seen(ReadEvent)

---

## 6. Правила для Codex

- Не змінювати семантику DSL
- Не вигадувати нові predicates без позначки
- Використовувати mapping як канон
- Всі відхилення явно позначати як extension

---

## 7. Висновок

DSL сценарії розглядаються як executable MSC з розширеннями.
