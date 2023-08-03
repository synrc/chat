defmodule CHAT.Client do
    require CHAT

    def ctx(),  do: :application.get_env(:chat, :ctx, [])
    def home(), do: :application.set_env(:chat, :ctx, ["01-WELCOME"])
    def findScreen(name) do
        {name,screen} = :lists.keyfind(name, 1, list())
        screen
    end
    def list() do
      [
        { CHAT.screen(welcome(), :name), welcome() },
        { CHAT.screen(reg(),     :name), reg() },
        { CHAT.screen(profile(), :name), profile() }
      ]
    end
    def show() do
        [ctx] = ctx()
        CHAT.screen(sections: [CHAT.section(name: name, rows: rows)]) = findScreen(ctx)
        :io.format '\e[0m\e[1;97m\e[45m    \e[0;97m\e[1;104m ~ts ~n\e[0m\e[0K', [name]
        :lists.map(fn CHAT.row(no: no, desc: desc, rico: _rico) ->
           :io.format '\e[0m\e[1;97m\e[45m ~2.. B \e[0;93m\e[0;104m ~40.. ts ~n\e[0m\e[0K', [no,desc]
        end, rows)
        :ok
    end

    def welcome() do
        CHAT.screen(no: 1, name: "01-WELCOME", sections:
         [CHAT.section(name: "Вітаємо в CHAT!", rows: [
           CHAT.row(no: 1, desc: "Реєстрація", rico: {:more, "02-REG"}),
           CHAT.row(no: 2, desc: "Авторизація", rico: :more),
           CHAT.row(no: 3, desc: "Імпорт", rico: :more)
         ])])
    end

    def reg() do
        CHAT.screen(no: 2, name: "02-REG", sections:
         [CHAT.section(name: "Реєстрація", rows: [
           CHAT.row(no: 1, desc: "Позивний", rico: :text),
           CHAT.row(no: 2, desc: "Пароль", rico: :pin),
           CHAT.row(no: 3, desc: "Продовжити", rico: {:more,"03-PROFILE"})
         ])])
    end

    def profile() do
        CHAT.screen(no: 3, name: "03-PROFILE", sections:
          [CHAT.section(name: "Налаштування профілю", rows: [
            CHAT.row(no: 1, desc: "Profile ID", rico: :export),
            CHAT.row(no: 2, desc: "Відкритий ключ", rico: :search),
            CHAT.row(no: 3, desc: "Налаштування ключів", rico: :more),
            CHAT.row(no: 4, desc: "Налаштування серверів", rico: :more),
            CHAT.row(no: 5, desc: "Прив'язаний номер", rico: :more),
            CHAT.row(no: 6, desc: "Прив'язаний E-Mail", rico: :more),
            CHAT.row(no: 7, desc: "Блокування паролем", rico: :toggle),
            CHAT.row(no: 8, desc: "Приватність", rico: :more),
            CHAT.row(no: 9, desc: "Export ID", rico: :export),
            CHAT.row(no: 10, desc: "Сховище і дані", rico: :more),
            CHAT.row(no: 11, desc: "Видалити дані ID", rico: :bin),
            CHAT.row(no: 12, desc: "Видалити профіль", rico: :bin)
        ])])
    end

end