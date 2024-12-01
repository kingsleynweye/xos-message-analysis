import io
from pathlib import Path
import pandas as pd
import plistlib
import re
import subprocess
from typing import Any
import nltk
import spacy
from typedstream.stream import TypedStreamReader
from src.database import SQLiteDatabase
from src.utilities import FileHandler

class Data:
    def __init__(self, database: SQLiteDatabase, filepath: Path | str = None, query: Path | str = None, batch_insert: bool = None, batch_size: int = None) -> None:
        self.database = database
        self.filepath = filepath
        self.query = query
        self.batch_insert = batch_insert
        self.batch_size = batch_size
        self.__query_list = []
        self.__values_list = []

    @property
    def batch_size(self) -> int:
        return self.__batch_size
    
    @property
    def batch_insert(self) -> bool:
        return self.__batch_insert

    @batch_size.setter
    def batch_size(self, value: int):
        self.__batch_size = 10_000 if value is None else value

    @batch_insert.setter
    def batch_insert(self, value: bool):
        self.__batch_insert = False if value is None else value

    def update(self):
        self.set_insert_data()

        if self.batch_insert:
            for q, v in zip(self.__query_list, self.__values_list):
                for i in range(0, v.size[0], self.batch_size):
                    v = pd.DataFrame(v).iloc[i:i + self.batch_size].to_dict('records')
                    self.database.insert_batch([q], [v])        
        else:
            self.database.insert_batch(self.__query_list, self.__values_list)

    def set_insert_data(self):
        raise NotImplementedError
    
    def update_lists(self, query: str, values: pd.DataFrame):
        self.__query_list.append(query)
        self.__values_list.append(values.to_dict('records'))
    
    def get_data(self) -> pd.DataFrame:
        if self.query is not None:
            query = FileHandler.get_data_from_path(self.query)
            data = self.database.query_table(query)

        elif self.filepath is not None and self.filepath.endswith('.csv'):
            data = pd.read_csv(self.filepath)

        else:
            raise NotImplementedError
        
        return data
    
class HandleIDBlacklist(Data):
    def __init__(self, *args, filepath: Path | str = None, **kwargs):
        filepath = FileHandler.HANDLE_ID_BLACKLIST_FILEPATH if filepath is None else filepath
        super().__init__(*args, filepath=filepath, **kwargs)

    def set_insert_data(self):
        self.update_lists("""
            INSERT INTO handle_blacklist (handle_id) VALUES (:handle_id)
            ON CONFLICT (handle_id) DO NOTHING
            ;""", self.get_data())

class Contacts(Data):
    NAME_COLUMNS = [
        'Last Name',
        'First Name',
        'Middle Name',
    ]

    def __init__(self, *args, filepath: Path | str, **kwargs) -> None:
        filepath = FileHandler.CONTACTS_FILEPATH if filepath is None else filepath
        super().__init__(*args, filepath=filepath, **kwargs)

    def set_insert_data(self):
        data = self.get_data()
        
        name_data = data.melt(id_vars=['id'], value_vars=self.NAME_COLUMNS).dropna()
        self.update_lists("INSERT INTO contact_name (value) VALUES (:value) ON CONFLICT (value) DO NOTHING;", name_data)

        company_data = data[['Organization Name']].dropna().copy()
        company_data.columns = [c.lower().replace(' ', '_') for c in company_data.columns]
        self.update_lists("INSERT INTO contact_company (value) VALUES (:organization_name) ON CONFLICT (value) DO NOTHING;", company_data)

        department_data = data[['Organization Department']].dropna().copy()
        department_data.columns = [c.lower().replace(' ', '_') for c in department_data.columns]
        self.update_lists(
            "INSERT INTO contact_department (value) VALUES (:organization_department) ON CONFLICT (value) DO NOTHING;", 
            department_data)

        contact_data = data[self.NAME_COLUMNS + ['id', 'Organization Name', 'Organization Department']].copy()
        contact_data.columns = [c.lower().replace(' ', '_') for c in contact_data.columns]
        self.update_lists("""
            INSERT INTO contact (id, first_name_id, last_name_id, middle_name_id, company_id, department_id)
            VALUES (
                :id,
                (SELECT id FROM contact_name WHERE value = :first_name),
                (SELECT id FROM contact_name WHERE value = :last_name),
                (SELECT id FROM contact_name WHERE value = :middle_name),
                (SELECT id FROM contact_company WHERE value = :organization_name),
                (SELECT id FROM contact_department WHERE value = :organization_department)
            );""", contact_data)

        phone_number_data = self.__get_phone_number_data(data)
        self.update_lists("INSERT INTO phone_number (value) VALUES (:phone_number) ON CONFLICT (value) DO NOTHING;", phone_number_data)
        self.update_lists("""
            INSERT INTO contact_phone_number (contact_id, phone_number_id)
            VALUES (
                :id,
                (SELECT id FROM phone_number WHERE value = :phone_number)
            );""", phone_number_data)

        email_address_data = self.__get_email_address_data(data)
        self.update_lists("INSERT INTO email_address (value) VALUES (:email_address) ON CONFLICT (value) DO NOTHING;", email_address_data)
        self.update_lists("""
            INSERT INTO contact_email_address (contact_id, email_address_id)
            VALUES (
                :id,
                (SELECT id FROM email_address WHERE value = :email_address)
            );""", email_address_data)

    def __get_phone_number_data(self, data: pd.DataFrame) -> pd.DataFrame:
        columns = [c for c in data.columns if c.startswith('Phone ') and c.endswith('- Value')]
        data = data[['id'] + columns].copy()
        data['phone_number'] = data.apply(lambda x: ' ::: '.join(
            [x[c] for c in columns if isinstance(x[c], str)]
        ).split(' ::: '), axis=1)
        data = data[['id', 'phone_number']].explode('phone_number')
        data = data[data['phone_number'] != ''].copy()
        
        return data

    def __get_email_address_data(self, data: pd.DataFrame) -> pd.DataFrame:
        columns = [c for c in data.columns if c.startswith('E-mail ') and c.endswith('- Value')]
        data = data[['id'] + columns].copy()
        data['email_address'] = data.apply(lambda x: ' ::: '.join(
            [x[c] for c in columns if isinstance(x[c], str)]
        ).split(' ::: '), axis=1)
        data = data[['id', 'email_address']].explode('email_address')
        data = data[data['email_address'] != ''].copy()
        
        return data
    
    def get_data(self) -> pd.DataFrame:
        data = super().get_data()
        data['id'] = data.index + 1

        return data

class CountryAreaCode(Data):
    COUNTRY_CALL_CODE_DATA_URL = 'https://raw.githubusercontent.com/datasets/country-codes/refs/heads/main/data/country-codes.csv'
    COUNTRY_COORDINATE_DATA_URL = 'https://gist.githubusercontent.com/tadast/8827699/raw/61b2107766d6fd51e2bd02d9f78f6be081340efc/countries_codes_and_coordinates.csv'

    def __init__(self, *args, **kwargs) -> None:
        super().__init__(*args, **kwargs)

    def set_insert_data(self):
        data = self.get_data()

        self.update_lists(
            "INSERT INTO area_code_metadata (value) VALUES (:dial) ON CONFLICT (value) DO NOTHING;", 
            data.drop_duplicates(subset=['dial']))
        self.update_lists("""
            INSERT INTO country_metadata (name, fips, area_code_id, latitude, longitude)
            VALUES (:country, :fips, (SELECT id FROM area_code_metadata WHERE value = :dial), :latitude, :longitude)
            ON CONFLICT (name, area_code_id) DO UPDATE SET (fips,latitude, longitude) 
                = (EXCLUDED.fips, EXCLUDED.latitude, EXCLUDED.longitude)
            ;""", data)

    def get_data(self) -> pd.DataFrame:
        data = self.__get_call_code_data()[[
            'official_name_en', 'dial', 'fips', 'iso3166_1_numeric'
        ]].merge(
            self.__get_coordinates_data()[[
                'country', 'latitude_(average)', 'longitude_(average)', 'numeric_code'
            ]],
            left_on='iso3166_1_numeric',
            right_on='numeric_code',
            how='inner'
        )
        data[['latitude', 'longitude']] = data[['latitude_(average)', 'longitude_(average)']].astype(float)
        data = data.drop_duplicates()

        # remove UK since we want to add 7 to the 44 explicitly
        data = data[data['country']!='United Kingdom'].copy()

        return data

    def __get_coordinates_data(self) -> pd.DataFrame:
        data = pd.read_csv(self.COUNTRY_COORDINATE_DATA_URL, dtype=str)
        data.columns = [c.lower().replace('-', '_').replace(' ', '_') for c in data.columns]

        for c in data.columns:
            data[c] = data[c].str.replace('"', '').str.strip()

        return data

    def __get_call_code_data(self) -> pd.DataFrame:
        data = pd.read_csv(self.COUNTRY_CALL_CODE_DATA_URL, dtype=str)
        data.columns = [c.lower().replace('-', '_').replace(' ', '_') for c in data.columns]
        data['dial'] = data['dial'].map(lambda x: x.split(','))
        data['id'] = data.index
        call_code_dial_data = data[['id', 'dial']].explode('dial')
        data = data.drop(columns=['dial'])
        data = data.merge(call_code_dial_data, on='id')
        data['dial'] = data['dial'].map(lambda x: x.replace('-', ''))
        data = data[(data['dial'].notnull()) & (data['dial']!='')].copy()

        return data

class CityAreaCode(Data):
    CANADA_CITIES_AREA_CODE_DATA_URL = 'https://raw.githubusercontent.com/ravisorg/Area-Code-Geolocation-Database/refs/heads/master/ca-area-code-cities.csv'
    US_CITIES_AREA_CODE_DATA_URL = 'https://raw.githubusercontent.com/ravisorg/Area-Code-Geolocation-Database/refs/heads/master/us-area-code-cities.csv'

    def __init__(self, *args, **kwargs) -> None:
        super().__init__(*args, **kwargs)
    
    def set_insert_data(self):
        data = self.get_data()

        self.update_lists(
            "INSERT INTO city_name (name) VALUES (:city) ON CONFLICT (name) DO NOTHING;", data.drop_duplicates(subset=['city']))
        self.update_lists(
            "INSERT INTO state_name (name) VALUES (:state) ON CONFLICT (name) DO NOTHING;", data.drop_duplicates(subset=['state']))
        self.update_lists("INSERT INTO area_code_metadata (value) VALUES (:area_code) ON CONFLICT (value) DO NOTHING;", data.drop_duplicates(subset=['area_code']))
        self.update_lists("""
            INSERT INTO city_metadata (country_id, city_name_id, state_name_id, area_code_id, latitude, longitude)
            VALUES (
                (SELECT id FROM country_metadata WHERE fips = :country_fips),
                (SELECT id FROM city_name WHERE name = :city),
                (SELECT id FROM state_name WHERE name = :state),
                (SELECT id FROM area_code_metadata WHERE value = :area_code),
                :latitude,
                :longitude
            );""", data)
    
    def get_data(self) -> pd.DataFrame:
        data = pd.concat([
            pd.read_csv(self.US_CITIES_AREA_CODE_DATA_URL, header=None),
            pd.read_csv(self.CANADA_CITIES_AREA_CODE_DATA_URL, header=None)
        ], ignore_index=True)
        data.columns = ['area_code', 'city', 'state', 'country_fips', 'latitude', 'longitude']
        data = data.drop_duplicates(subset=['area_code', 'country_fips', 'city', 'state'])
        
        return data
    
class MessageAttributedBody(Data):
    def __init__(self, *args, query: Path | str = None, **kwargs) -> None:
        query = """
        SELECT
            ROWID AS message_rowid,
            attributedBody AS attributed_body
        FROM message
        ;""" if query is None else query
        super().__init__(*args, query=query, **kwargs)

    def set_insert_data(self):
        self.update_lists("""
            INSERT INTO parsed_message_attributed_body (message_rowid, value) 
            VALUES (:message_rowid, :attributed_body)
            ON CONFLICT (message_rowid) DO NOTHING
            ;""", self.get_data().dropna(subset=['attributed_body']))
        
    def get_data(self) -> pd.DataFrame:
        data = super().get_data()
        data = self.__get_preprocessd_data(data)

        return data

    def __get_preprocessd_data(self, data: pd.DataFrame) -> pd.DataFrame:
        data['attributed_body'] = data['attributed_body'].map(lambda x: [
        e.decode('utf-8') for e in TypedStreamReader.from_data(x) if type(e) is bytes][0] 
            if x else None)
        
        return data

class DashboardMessage(Data):
    def __init__(self, *args, query: Path | str = None, **kwargs) -> None:
        query = FileHandler.INSERT_DASHBOARD_MESSAGES_QUERY_FILEPATH if query is None else query
        super().__init__(*args, query=query, **kwargs)

    def update(self):
        subprocess.run(
            ['sqlite3', self.database.filepath], 
            input=open(self.query, 'r').read(), 
            text=True
        )

class GrafanaUserMetadata(Data):
    def __init__(self, *args, filepath: Path | str = None, **kwargs) -> None:
        filepath = FileHandler.GRAFANA_USER_METADATA_FILEPATH if filepath is None else filepath
        super().__init__(*args, filepath=filepath, **kwargs)

    def set_insert_data(self):
        data = self.get_data()

        self.update_lists("""
            INSERT INTO email_address (value)
                VALUES (:email_address) ON CONFLICT DO NOTHING
            ;""", data.drop_duplicates(subset=['email_address']))
        
        self.update_lists("""
            INSERT INTO grafana_user_metadata (email_address_id, contact_reference_handle_rowid, restrict_view)
                VALUES (
                    (SELECT id FROM email_address WHERE value = :email_address),
                    (SELECT handle_rowid FROM contact_handle_map WHERE handle_id = :contact_reference_handle_id LIMIT 1),
                    :restrict_view
                ) ON CONFLICT (email_address_id) DO NOTHING
            ;""", data)
        
class GrafanaRestrictedUserHandleWhitelist(Data):
    def __init__(self, *args, query: Path | str = None, **kwargs) -> None:
        query = """
        SELECT
            m.id AS user_id,
            r.handle_rowid
        FROM grafana_user_metadata m
        LEFT JOIN contact_handle_map h ON h.handle_rowid = m.contact_reference_handle_rowid
        LEFT JOIN contact_handle_map r ON r.contact_id = h.contact_id
        WHERE m.restrict_view = 1
        ;
        """ if query is None else query
        super().__init__(*args, query=query, **kwargs)

    def set_insert_data(self):
        data = self.get_data()

        self.update_lists("""
            INSERT INTO grafana_restricted_user_handle_whitelist ("user_id", handle_rowid)
            VALUES (:user_id, :handle_rowid)
            ON CONFLICT ("user_id", handle_rowid) DO NOTHING;""", data)
            
class Gamepigeon(Data):
    __OBJECT_FILTERS = [
        '$null',
        'ldtext',
        'userInfo',
        'an',
        'ai',
        'sessionIdentifier',
        'liveLayoutInfo',
        'layoutClass',
        'URL',
        'image-subtitle',
        'image-title',
        'caption',
        'secondary-subcaption',
        'tertiary-subcaption',
        'subcaption',
        '',
        'GamePigeon',
    ]
    
    def __init__(self, *args, query: Path | str = None, **kwargs) -> None:
        query = """
        SELECT
            t.contact_display_name,
            t.handle_rowid,
            t.unix_timestamp,
            t.message_rowid,
            m.is_from_me,
            t.message_text,
            m.attributedBody AS attributed_body,
            m.payload_data,
            m.message_summary_info,
            m.associated_message_guid
        FROM dashboard_message_summary t
        LEFT JOIN message m ON m.ROWID = t.message_rowid
        LEFT JOIN parsed_message_attributed_body p ON p.message_rowid = m.ROWID
        WHERE
            t.is_gamepigeon_message = 1
        ORDER BY
            t.contact_display_name,
            t.timestamp
        ;""" if query is None else query
        super().__init__(*args, query=query, **kwargs)

    def set_insert_data(self):
        self.update_lists("""
            INSERT INTO gamepigeon_session (associated_message_guid, unix_start_timestamp, unix_end_timestamp, application_id, termination_type_id, opponent_handle_rowid, my_points, opponent_points)
            VALUES (
            :associated_message_guid,
            :unix_start_timestamp,
            :unix_end_timestamp,
            (SELECT id FROM gamepigeon_application WHERE name = :appid),
            :termination_type_id,
            :opponent_handle_rowid,
            :my_points,
            :opponent_points
            ) ON CONFLICT (associated_message_guid) DO NOTHING
            ;""", self.get_data())

    def get_data(self) -> pd.DataFrame:
        data = super().get_data()
        data = self.__parse_payload_data(data)
        data = self.__get_games_data(data)

        return data

    def __get_games_data(self, data: pd.DataFrame) -> pd.DataFrame:
        games = []
        valid_appids = self.__get_valid_appids()

        for guid, gdata in data.groupby('associated_message_guid'):
            # identify app id
            appids = gdata['message_text'].tolist()
            
            for l in gdata['payload_data_clean_objects'].tolist():
                appids += l

            appids = [a.replace("Let's play ", '') for a in appids if a is not None]
            appids = [a for a in appids if a in valid_appids]
            appids = list(set(appids))
            assert len(appids) == 1
            appid = appids[0]
            gdata['appid'] = appid

            # identify winning message
            gdata['win_messages'] = gdata.apply(lambda x: 
                [x['message_text']] + x['payload_data_clean_objects'], axis=1)
            gdata['win_messages'] = gdata['win_messages'].map(lambda x: [
                x_ for x_ in x if x_ is not None and 
                    (' won' in x_.lower() or 'draw' in x_.lower())])
            gdata['win_messages_length'] = gdata['win_messages'].map(lambda x: len(x))
            assert gdata['win_messages_length'].max() <= 1
            gdata['win_message'] = gdata['win_messages'].map(lambda x: x[0] if len(x) > 0 else None)
            gdata['win_message'] = gdata['win_message'].str.lower()
            win_messages = gdata['win_message'].dropna().tolist()
            win_message = None

            if len(win_messages) == 1:
                win_message = win_messages[0]

                if win_message == 'draw!':
                    gdata['termination_type_id'] = 3
                
                elif win_message == 'i won!':
                    winner_is_me = gdata[gdata['win_message']==win_message].iloc[0]['is_from_me']

                    if bool(winner_is_me):
                        gdata['termination_type_id'] = 1

                    else:
                        gdata['termination_type_id'] = 2

                elif win_message == 'you won!':
                    winner_is_not_me = gdata[gdata['win_message']==win_message].iloc[0]['is_from_me']

                    if bool(winner_is_not_me):
                        gdata['termination_type_id'] = 2

                    else:
                        gdata['termination_type_id'] = 1

                else:
                    raise Exception(f'Unknown win message: {win_message}')

            elif len(win_messages) == 2:
                assert 'i won!' in win_messages and 'you won!' in win_messages
                winner_is_me = gdata[gdata['win_message']=='i won!'].iloc[0]['is_from_me']

                if bool(winner_is_me):
                    gdata['termination_type_id'] = 1

                else:
                    gdata['termination_type_id'] = 2

            elif len(win_messages) == 0:
                gdata['termination_type_id'] = 4

            else:
                raise Exception(f'Too many win message (greater than 2): {len(win_messages)}')

            # points
            gdata['points_messages'] = gdata.apply(lambda x: 
                [x['message_text']] + x['payload_data_clean_objects'], axis=1)
            gdata['points_messages'] = gdata['points_messages'].map(lambda x: [
                x_ for x_ in x if x_ is not None and ' points' in x_.lower()])
            gdata['points_messages'] = gdata['points_messages'].map(lambda x: list(set(x)))
            gdata['points_messages_length'] = gdata['points_messages'].map(lambda x: len(x))
            assert gdata['points_messages_length'].max() <= 1
            gdata['points'] = gdata['points_messages'].map(lambda x: None if len(x) == 0 else int(re.sub('\D+', '', x[0])))
            points_data = gdata[['is_from_me', 'points']].dropna(subset=['points']).drop_duplicates()
            assert len(points_data) <= 2
            gdata['my_points'] = None
            gdata['opponent_points'] = None

            if len(points_data) > 0:
                my_points_data = points_data[points_data['is_from_me']==1].copy()
                opponent_points_data = points_data[points_data['is_from_me']==0].copy()
                my_points = None
                opponent_points = None

                if len(my_points_data) > 0:
                    my_points = my_points_data['points'].iloc[0]
                
                else:
                    pass

                if len(opponent_points_data) > 0:
                    opponent_points = opponent_points_data['points'].iloc[0]
                
                else:
                    pass

                gdata['my_points'] = my_points
                gdata['opponent_points'] = opponent_points
                existing_termination_type_id = gdata['termination_type_id'].iloc[0]

                if my_points is not None and opponent_points is not None:
                    if my_points == opponent_points:
                        termination_type_id = 3
                    
                    elif my_points > opponent_points:
                        termination_type_id = 1
                    
                    else:
                        termination_type_id = 2


                elif win_message is not None:
                    termination_type_id = existing_termination_type_id

                else:
                    termination_type_id = 4
                
                assert existing_termination_type_id is None \
                    or existing_termination_type_id == 4 \
                        or existing_termination_type_id == termination_type_id \
                            or len(win_messages) == 1
                gdata['termination_type_id'] = termination_type_id

            else:
                pass
            
            games.append(dict(
                associated_message_guid=guid,
                unix_start_timestamp=gdata['unix_timestamp'].min(),
                unix_end_timestamp=gdata['unix_timestamp'].max(),
                opponent_handle_rowid=gdata['handle_rowid'].iloc[0],
                appid=appid,
                termination_type_id=gdata['termination_type_id'].iloc[0],
                my_points=gdata['my_points'].iloc[0],
                opponent_points=gdata['opponent_points'].iloc[0],
            ))

        games = pd.DataFrame(games)

        return games
    
    def __get_valid_appids(self) -> list[str]:
        data = self.database.query_table("SELECT name FROM gamepigeon_application;")['name'].tolist()

        return data

    def __parse_payload_data(self, data: pd.DataFrame) -> pd.DataFrame:
        data['payload_data_raw'] = data['payload_data'].map(lambda x: plistlib.load(io.BytesIO(x)))
        data['payload_data_raw_objects'] = data['payload_data_raw'].map(lambda x: x['$objects'])
        data['payload_data_clean_objects'] = data['payload_data_raw_objects'].map(lambda x: self.__get_clean_objects(x))
        data['payload_data_appid'] = data['payload_data_clean_objects'].map(lambda x: x[x.index('appid') + 1])

        return data

    def __get_clean_objects(self, x: list[Any]) -> list[str]:
        x = [o for o in x if isinstance(o, str) and o not in self.__OBJECT_FILTERS and not o.startswith('data:')]

        return x
        
class WordCloud(Data):
    def __init__(self, *args, query: Path | str = None, **kwargs) -> None:
        query = """
        SELECT
            t.message_rowid,
            t.message_text
        FROM dashboard_message_summary t
        WHERE
            t.message_text IS NOT NULL
            AND REPLACE(t.message_text, ' ', '') != ''
            AND t.is_audio_message = 0
            AND t.is_gamepigeon_message = 0
        ;""" if query is None else query
        super().__init__(*args, query=query, **kwargs)

    def set_insert_data(self):
        data = self.get_data()
    
        self.update_lists("""
            INSERT INTO word_cloud_word (value) 
            VALUES (:processed_text) 
            ON CONFLICT (value) DO NOTHING;""", data.drop_duplicates(subset=['processed_text']))
        self.update_lists("""
            INSERT INTO word_cloud_word_message (message_rowid, word_id) 
            VALUES (:message_rowid, (SELECT id FROM word_cloud_word WHERE value = :processed_text)) 
            ;""", data)

    def get_data(self) -> pd.DataFrame:
        data = super().get_data()
        data = self.__preprocess_data(data)

        return data

    def __preprocess_data(self, data: pd.DataFrame) -> pd.DataFrame:
        self.__download_nltk_resources()
        nlp = spacy.load('en_core_web_sm')
        tokens = []
        lemma = []
        pos = []
        minimum_word_length_limit = 2
        data['processed_text'] = data['message_text'].tolist()

        # convert to lowercase
        data['processed_text'] = data['processed_text'].str.lower()

        # lemmatize
        for doc in nlp.pipe(data['processed_text'].astype('unicode').values, batch_size=10_000, n_process=8):
            if doc.is_parsed:
                tokens.append([n.text for n in doc])
                lemma.append([n.lemma_ for n in doc])
                pos.append([n.pos_ for n in doc])
            
            else:
                # We want to make sure that the lists of parsed results have the
                # same number of entries of the original Dataframe, so add some blanks in case the parse fails
                tokens.append(None)
                lemma.append(None)
                pos.append(None)

        data['processed_text'] = lemma

        # remove numeric and non textual and whitespace characters
        data['processed_text'] = data['processed_text'].map(lambda x: [
            re.sub(r'\d+|[^\w|\s]', '', word) if isinstance(word, str) else x for word in x])

        # exclude words less than the allowed word character limit
        data['processed_text'] = data['processed_text'].map(lambda x: [word.strip() for word in x if len(word.strip()) >= minimum_word_length_limit])

        # remove stopwords
        data['processed_text'] = data['processed_text'].map(lambda x: [word for word in x if word not in nltk.corpus.stopwords.words('english')])

        # explode list of words
        data = data[['message_rowid', 'processed_text']].explode('processed_text').dropna()

        return data

    def __download_nltk_resources(self):
        nltk.download([
            'names',
            'stopwords',
            'state_union',
            'twitter_samples',
            'movie_reviews',
            'averaged_perceptron_tagger',
            'vader_lexicon',
            'punkt',
            'punkt_tab',
            'wordnet',
        ], quiet=True, raise_on_error=True)