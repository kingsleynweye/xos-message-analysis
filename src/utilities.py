import os
from pathlib import Path
import yaml

class FileHandler:
    ROOT_DIRECTORY = os.path.join(*Path(os.path.dirname(os.path.abspath(__file__))).parts[0:-1])
    DATA_DIRECTORY = os.path.join(ROOT_DIRECTORY, 'data')
    DATABASE_DESTINATION_FILEPATH = os.path.join(DATA_DIRECTORY, 'chat.db')
    DATABASE_SOURCE_FILEPATH = os.path.join(Path.home(), 'Library', 'Messages', 'chat.db')
    CONTACTS_FILEPATH = os.path.join(DATA_DIRECTORY, 'contacts.csv')
    HANDLE_ID_BLACKLIST_FILEPATH = os.path.join(DATA_DIRECTORY, 'handle_id_blacklist.csv')
    QUERIES_DIRECTORY = os.path.join(ROOT_DIRECTORY, 'sql')
    CREATE_RELATIONS_QUERY_FILEPATH = os.path.join(QUERIES_DIRECTORY, 'create_relations.sql')
    CREATE_INDEXES_QUERY_FILEPATH = os.path.join(QUERIES_DIRECTORY, 'create_indexes.sql')
    INSERT_PRELIMINARY_QUERY_FILEPATH = os.path.join(QUERIES_DIRECTORY, 'insert_preliminary.sql')
    INSERT_DASHBOARD_MESSAGES_QUERY_FILEPATH = os.path.join(QUERIES_DIRECTORY, 'insert_dashboard_messages.sql')
    
    def read_yaml(filepath: str) -> dict:
        """Return YAML document as dictionary.
        
        Parameters
        ----------
        filepath : str
        pathname of YAML document.
        
        Returns
        -------
        dict
            YAML document converted to dictionary.
        """

        with open(filepath, 'r') as f:
            data = yaml.safe_load(f)

        return data

    def write_yaml(filepath: str, dictionary: dict, **kwargs):
        """Write dictionary to YAML file. 
        
        Parameters
        ----------
        filepath : str
            pathname of YAML document.
        dictionary: dict
            dictionary to convert to YAML.

        Other Parameters
        ----------------
        **kwargs : dict
            Other infrequently used keyword arguments to be parsed to `yaml.safe_dump`.
        """

        kwargs = {'sort_keys': False, 'indent': 2, **kwargs}
        
        with open(filepath, 'w') as f:
            yaml.safe_dump(dictionary, f, **kwargs)

    def get_data_from_path(filepath: Path | str) -> Path | str:
        if os.path.exists(filepath):
            with open(filepath,mode='r') as f:
                data = f.read()
        
        else:
            data = filepath

        return data