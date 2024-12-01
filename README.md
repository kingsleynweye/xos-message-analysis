# xOS Message Analysis
Inspired by arguments with friends about who has more Gamepigeon's 8-ball pool wins, this repository provides _Pythonic_ source-code to process the `chat.db` `SQLite` database that is stored in Apple's Mac computers. 

The processing includes creating new views and tables in the database that summarize the data better including tokenization of messages for use in generating word clouds. The processed data are used in a Grafana dashboard that analyzes owner's messaging patterns and behaviors in the Messages app on iOS, MacOS, iPadOS, and any other <em>x</em>OS.

## Installation
At the moment, the best way to utilize this project is to clone the repository and install the Python dependencies:

```console
git clone https://github.com/kingsleynweye/xos-message-analysis.git
cd xos-message-analysis
pip install -r requirements.txt
python -m spacy download en_core_web_sm
```

Note that the source-code has been written based on the `chat.db` schema used in `MacOS Ventura 13.0`.

## Usage
To process the database, run the following command at a minimum:

```console
python -m src.main process_database -c
```

It will first copy the database from `~/Library/Messages/chat.db` to `data/chat.db` (in the repository's root directory) before processing the data using the `src.ProcessDatabase` class.

## Use of ChatGPT
A lot of debugging and data wrangling went into this project and there doesn't seem to be any actual documentation on the `chat.db` schema by Apple, so ChatGPT became my companion on this project. Here are some of our public chats that helped with debugging SQLite and the schema (titles are ChatGPT-generated):

- [SQLite Performance Optimization](https://chatgpt.com/share/674a03a6-ad48-8010-bf15-516bca55bc1e)
- [SQLite query hanging fix](https://chatgpt.com/share/674a00e4-d720-8010-980c-38a6a267098d)
- [Is_emote field explanation](https://chatgpt.com/share/674a02e9-dbc8-8010-b03f-6fce1a299458)
- [Regex Replace in SQLite](https://chatgpt.com/share/674a0237-5d54-8010-9b75-e84381d13cea)
- [Export iOS Contacts Database](https://chatgpt.com/share/674a0201-3bc0-8010-8689-9fe1f4623837)
- [Group by Day SQLite](https://chatgpt.com/share/674a01c9-7530-8010-863d-bfd6bdfd65e1)
- [Query iMessage 8 Ball Wins](https://chatgpt.com/share/674a017b-1aec-8010-8f80-c3046f792f38)

## Other need-to-knows
More documentation to come 😉