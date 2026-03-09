import pymysql

def get_db_connection():
    connection = pymysql.connect(
        host='sql10.freesqldatabase.com',
        user='sql10819053',
        password='v9WkdTVDR2',
        database='sql10819053',
        cursorclass=pymysql.cursors.DictCursor
    )
    return connection