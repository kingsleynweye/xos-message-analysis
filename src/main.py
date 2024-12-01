import argparse
import inspect
import logging
import os
from pathlib import Path
import shutil
from typing import Any
import sys
import simplejson as json
from src.data import (
    CityAreaCode,
    Contacts,
    CountryAreaCode,
    DashboardMessage,
    Gamepigeon,
    GrafanaUserMetadata,
    HandleIDBlacklist,
    MessageAttributedBody,
    GrafanaRestrictedUserHandleWhitelist,
    WordCloud,
)
from src.database import SQLiteDatabase
from src.utilities import FileHandler

LOGGER = logging.getLogger()
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s: %(message)s')

class ProcessDatabase:
    def __init__(self, database_source_filepath: Path | str = None, database_destination_filepath: Path | str = None, database_kwargs: dict[str, Any] = None, contacts_filepath: Path | str = None, handle_id_blacklist_filepath: Path | str = None, grafana_user_metadata_filepath: Path | str =  None, grafana_restricted_user_handle_whitelist_query: Path | str = None):
        self.database_source_filepath = database_source_filepath
        self.database_destination_filepath = database_destination_filepath
        self.database_kwargs = database_kwargs
        self.contacts_filepath = contacts_filepath
        self.handle_id_blacklist_filepath = handle_id_blacklist_filepath
        self.grafana_user_metadata_filepath = grafana_user_metadata_filepath
        self.grafana_restricted_user_handle_whitelist_query = grafana_restricted_user_handle_whitelist_query

    @property
    def database_source_filepath(self) -> Path | str:
        return self.__database_source_filepath
    
    @property
    def database_destination_filepath(self) -> Path | str:
        return self.__database_destination_filepath
    
    @property
    def database_kwargs(self) -> dict[str, Any]:
        return self.__database_kwargs
    
    @database_source_filepath.setter
    def database_source_filepath(self, value: Path | str):
        self.__database_source_filepath = FileHandler.DATABASE_SOURCE_FILEPATH if value is None else value

    @database_destination_filepath.setter
    def database_destination_filepath(self, value: Path | str):
        self.__database_destination_filepath = FileHandler.DATABASE_DESTINATION_FILEPATH if value is None else value
        directory = os.path.join(*Path(os.path.abspath(self.__database_destination_filepath)).parts[:-1])
        os.makedirs(directory, exist_ok=True)

    @database_kwargs.setter
    def database_kwargs(self, value: dict[str, Any]):
        self.__database_kwargs = {'timeout': 600} if value is None else value

    @staticmethod
    def run(copy: bool = None, kwargs: dict[str, Any] = None):
        LOGGER.debug(f'Started processing database ...')
        os.makedirs(FileHandler.DATA_DIRECTORY, exist_ok=True)

        kwargs = {} if kwargs is None else kwargs
        LOGGER.debug('Initializing ProcessDatabase model.')
        model = ProcessDatabase(**kwargs)

        if copy is not None and copy:
            LOGGER.debug(f'Copying database from \'{model.database_source_filepath}\''
                f' to \'{model.database_destination_filepath}\'.')
            _ = model.copy_source_database()
        
        else:
            LOGGER.debug('Set to not copy database.')

        LOGGER.debug(f'Creating relations in \'{FileHandler.CREATE_RELATIONS_QUERY_FILEPATH}\'.')
        model.get_database().execute_sql_from_file(FileHandler.CREATE_RELATIONS_QUERY_FILEPATH)

        LOGGER.debug(f'Inserting values in \'{FileHandler.INSERT_PRELIMINARY_QUERY_FILEPATH}\'.')
        model.get_database().execute_sql_from_file(FileHandler.INSERT_PRELIMINARY_QUERY_FILEPATH)

        LOGGER.debug(f'Updating HandleIDBlacklist data.')
        try:
            HandleIDBlacklist(model.get_database(), filepath=model.handle_id_blacklist_filepath).update()

        except FileNotFoundError:
            LOGGER.debug(f'No HandleIDBlacklist data found.' 
                ' If you did not provide a handle_id_blacklist_filepath, consider listing'
                    f' handles you want to blacklist in \'{FileHandler.HANDLE_ID_BLACKLIST_FILEPATH}\'.')
        
        LOGGER.debug(f'Updating Contacts data.')
        try:
            Contacts(model.get_database(), filepath=model.contacts_filepath).update()

        except FileNotFoundError:
            LOGGER.debug(f'No Contacts data found.' 
                ' If you did not provide a contacts_filepath, consider exporting your'
                    f' contacts via GMail to \'{FileHandler.HANDLE_ID_BLACKLIST_FILEPATH}\'.')
        
        LOGGER.debug(f'Updating CountryAreaCode data.')
        CountryAreaCode(model.get_database()).update()
        
        LOGGER.debug(f'Updating CityAreaCode data.')
        CityAreaCode(model.get_database()).update()

        LOGGER.debug(f'Updating MessageAttributedBody data.')
        MessageAttributedBody(model.get_database()).update()

        LOGGER.debug(f'Updating DashboardMessage data.')
        DashboardMessage(model.get_database()).update()

        LOGGER.debug(f'Updating GrafanaUserMetadata data.')
        try:
            GrafanaUserMetadata(model.get_database(), filepath=model.grafana_user_metadata_filepath).update()

        except FileNotFoundError:
            LOGGER.debug(f'No GrafanaUserMetadata data found.' 
                ' If you did not provide a grafana_user_filepath, consider providing your'
                    f' Grafana users metadata in \'{FileHandler.GRAFANA_USER_METADATA_FILEPATH}\'.')

        LOGGER.debug(f'Updating GrafanaRestrictedUserHandleWhitelist data.')
        GrafanaRestrictedUserHandleWhitelist(
            model.get_database(), query=model.grafana_restricted_user_handle_whitelist_query).update()
        
        LOGGER.debug(f'Updating Gamepigeon data.')
        Gamepigeon(model.get_database()).update()

        LOGGER.debug(f'Updating WordCloud data.')
        WordCloud(model.get_database()).update()
        
        LOGGER.debug(f'Creating indexes in \'{FileHandler.CREATE_INDEXES_QUERY_FILEPATH}\'.')
        model.get_database().execute_sql_from_file(FileHandler.CREATE_INDEXES_QUERY_FILEPATH)

        LOGGER.debug(f'Vacuuming database.')
        model.get_database().vacuum()

        LOGGER.debug(f'Finished processing database.')

    def get_database(self) -> SQLiteDatabase:
        return SQLiteDatabase(self.__database_destination_filepath, **self.database_kwargs)

    def copy_source_database(self) -> Path:
        if os.access(self.database_source_filepath, os.R_OK):
            filepath = shutil.copy(self.database_source_filepath, self.database_destination_filepath)
        
        else:
            raise Exception(f'Permission denied to access \'{self.database_source_filepath}\'')

        return filepath
    
class __ReadRunKwargsAction(argparse.Action):
    def __call__(self, parser: argparse.ArgumentParser, namespace: argparse.Namespace, values: list[str], option_string: str | None = None):
        kwargs = {}

        for k in values:
            if k.endswith('.json'):
                k = FileHandler.read_json(k)

            elif k.endswith('.yaml') or k.endswith('.yml'):
                k = FileHandler.read_yaml(k)

            else:
                k = json.loads(k)

            kwargs = {**kwargs, **k}

        setattr(namespace, self.dest, kwargs)
    
def main():
    parser = argparse.ArgumentParser(prog='ios_message_analysis', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    subparsers = parser.add_subparsers(title='subcommands', required=True, dest='subcommands')

    # run data processing
    subparser_process_database = subparsers.add_parser('process_database', help='Process chat.db for use in Grafana.')
    subparser_process_database.add_argument('-c', '--copy', dest='copy', action='store_true', help='Copy new database from source.')
    subparser_process_database.add_argument('-k', '--kwargs', dest='kwargs', nargs='+', action=__ReadRunKwargsAction, 
        help='Initialization parameters for src.ProcessDatabase. Can be provided as a JSON or YAML filepath, or JSON string.')
    subparser_process_database.set_defaults(func=ProcessDatabase.run)

    args = parser.parse_args()
    arg_spec = inspect.getfullargspec(args.func)
    kwargs = {key:value for (key, value) in args._get_kwargs() 
        if (key in arg_spec.args or (arg_spec.varkw is not None and key not in ['func','subcommands']))
    }
    args.func(**kwargs)

if __name__ == '__main__':
    sys.exit(main())