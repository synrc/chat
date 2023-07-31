defmodule CHAT.Client do
    require CHAT
 
    def profile() do
        CHAT.section(name: "Налаштування профілю", rows: [
          CHAT.row(desc: "Profile ID", rico: :export),
          CHAT.row(desc: "Відкритий ключ", rico: :search),
          CHAT.row(desc: "Налаштування ключів", rico: :more),
          CHAT.row(desc: "Налаштування серверів", rico: :more),
          CHAT.row(desc: "Прив'язаний номер", rico: :more),
          CHAT.row(desc: "Прив'язаний E-Mail", rico: :more),
          CHAT.row(desc: "Блокування паролем", rico: :toggle),
          CHAT.row(desc: "Приватність", rico: :more),
          CHAT.row(desc: "Export ID", rico: :export),
          CHAT.row(desc: "Сховище і дані", rico: :more),
          CHAT.row(desc: "Видалити дані ID", rico: :bin),
          CHAT.row(desc: "Видалити профіль", rico: :bin),
        ])
    end

end