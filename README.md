# xOS Message Analysis
Inspired by arguments with friends about who has more Gamepigeon's 8-ball pool wins, this repository provides _Pythonic_ source-code to process the `chat.db` `SQLite` database that is stored in Apple's Mac computers. 

The processing includes creating new views and tables in the database that summarize the data better including tokenization of messages for use in generating word clouds. The processed data are used in a Grafana dashboard that analyzes owner's messaging patterns and behaviors in the Message app on iOS, MacOS, iPadOS, and any other <em>x</em>OS.

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

```
python -m src.main process_database -c
```

It will first copy the database from `~/Library/Messages/chat.db` to `data/chat.db` (in the repository's directory) before processing the data using the `src.ProcessDatabase` class.

## Other need-to-knows
More documentation to come 😉