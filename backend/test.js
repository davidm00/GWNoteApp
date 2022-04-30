import { enablePromise, openDatabase, SQLiteDatabase } from 'react-native-sqlite-storage';

const tableName = 'fakeData';

enablePromise(true);

export const getDBConnection = async () => {
  return openDatabase(
    { name: 'fake', location: 'default' },
    ()=>{},
    (error)=>{console.log("Error: ", error)}
    );
};

export const createTable = async (db) => {
  // create table if not exists
  const query = `CREATE TABLE IF NOT EXISTS ${tableName}(
        value TEXT NOT NULL
    );`;

  await db.executeSql(query);
};