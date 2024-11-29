cd data
sqlite3 chat.db '.clone chat-new.db'
mv chat.db chat-old.db
mv chat-new.db chat.db
rm chat-old.db
