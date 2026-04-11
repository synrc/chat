# Documentation Map

Цей документ описує структуру документації та зв’язки між її частинами.

---

## Рівні моделі

Система розбита на кілька рівнів:

1. Spec — що це за система
2. Kernel — формальна модель
3. DSL — мова сценаріїв
4. Extensions — розширення поверх ядра

---

## 1. Spec

- spec/SPEC.md — загальна архітектура протоколу
- spec/ARCH-AUTH.md — auth / authority / IAM модель

Це точка входу для розуміння системи як продукту.

---

## 2. Kernel (формальна модель)

- kernel/DSL-SEMANTIC-KERNEL.md
- kernel/DSL-TYPED-KERNEL-REFINEMENT.md

Тут описано:

- state
- action
- observation
- predicate
- judgment

Це джерело істини.

---

## 3. DSL (surface language)

- dsl/core/DSL-CORE.md
- dsl/core/DSL-ADVANCED.md
- dsl/domain/*

DSL використовується як:

- інструмент дизайну
- сценарна мова
- спосіб перевірки логіки протоколу

DSL elaborates у kernel.

---

## 4. Extensions

### Auth
- extensions/auth/DSL-AUTH-KERNEL-EXTENSION.md
- extensions/auth/DSL-AUTH.md

Відповідає за:
- authentication
- session lifecycle
- tokens

---

### ABAC
- extensions/abac/DSL-ABAC-KERNEL-EXTENSION.md
- extensions/abac/DSL-ABAC.md

Відповідає за:
- authorization
- visibility
- policy

---

### Search
- extensions/search/DSL-SEARCH-KERNEL-EXTENSION.md
- extensions/search/DSL-SEARCH.md

Відповідає за:
- query/view layer
- projection
- filtering

---

## Як читати

### Варіант 1 — зверху вниз

1. spec/SPEC.md
2. dsl/core/DSL-CORE.md
3. kernel/DSL-SEMANTIC-KERNEL.md
4. kernel/DSL-TYPED-KERNEL-REFINEMENT.md
5. extensions/*

---

### Варіант 2 — через DSL

1. dsl/core/DSL-CORE.md
2. dsl/domain/*
3. kernel/DSL-SEMANTIC-KERNEL.md
4. kernel/DSL-TYPED-KERNEL-REFINEMENT.md

---

### Варіант 3 — через kernel

1. kernel/DSL-SEMANTIC-KERNEL.md
2. kernel/DSL-TYPED-KERNEL-REFINEMENT.md
3. extensions/*
4. DSL як приклади

---

## Головний принцип

DSL → elaboration → kernel → evaluation

- DSL — синтаксис
- kernel — істина
- extensions — уточнення поведінки

---

## Інтуїція

- kernel = математика
- DSL = мова
- extensions = правила гри
