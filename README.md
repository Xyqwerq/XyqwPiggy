# 🐷 XyqwPiggy

<p align="center">
  <img src="https://img.shields.io/badge/version-7.2-red?style=for-the-badge" alt="Version">
  <img src="https://img.shields.io/badge/status-active-brightgreen?style=for-the-badge" alt="Status">
  <img src="https://img.shields.io/badge/author-Xyqwerq-blue?style=for-the-badge" alt="Author">
  <img src="https://img.shields.io/badge/language-Lua-purple?style=for-the-badge" alt="Language">
</p>

<p align="center">
  <b>Universal Roblox script for Piggy (Book 1 & Book 2)</b><br>
  Item ESP • AutoFarm • Anti-Trap • SkinChanger • Auto-AFK
</p>

---

## 📖 О проекте

**XyqwPiggy** — универсальный скрипт для игры **Piggy** (Roblox). Работает на обеих книгах (Book 1 и Book 2). Основная задача — упростить сбор предметов, визуализировать игровые объекты и автоматизировать рутинные действия.

**Текущая версия:** `7.2` (SUPER FIX)
**Поддерживаемые PlaceId:** `4623386862` (Book 1), `5661005779` (Book 2)

---

## ⚡ Возможности

### 🎯 Основное
- **Список предметов** — все активные предметы на карте с 3D-превью
- **Scan** — ручное обновление списка
- **Search** — поиск предметов по имени
- **Take Item** — телепорт + подбор предмета по клику
- **Balance** — отображение Piggy Coins в реальном времени

### 🎨 ESP (подсветка)
- **ESP Items** — красные Highlight'ы на всех предметах
- **ESP Monster** — красные Highlight'ы на монстрах в радиусе 200 studs
- **ESP Players** — зелёные Highlight'ы на других игроках

### 🛡 Защита
- **Anti-Trap** — автоматический подъём при приближении к трапу (raycast, не втыкается в потолок)
- **Auto-AFK** — клик в центр экрана каждые 60 сек (не выкидывает за неактивность)

### 🤖 AutoFarm
- **Автоматический запуск игры** (JoinGame / Play)
- **Установка карты Gallery + Mode Swarm** через VIP-команды
- **Skip таймера** — моментальный старт игры
- **Сбор предметов** — телепорт + fireclickdetector
- **Auto-Loop** — цикл после окончания игры
- **Предупреждение** — работает только на PRIVATE серверах

### 🎨 SkinChanger
- Кнопка в заголовке → загрузка внешнего скрипта SkinChanger через `loadScriptFromURL`
- 3 fallback-метода: `game:HttpGet`, `request`, `http_request`

---

## 🚀 Установка

### Способ 1: Loadstring (рекомендуется)

Скопируй и вставь в свой экзекьютор:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Xyqwerq/XyqwPiggy/main/main.lua"))()
