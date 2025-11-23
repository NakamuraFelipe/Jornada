import pymysql

def get_db_connection():
    connection = pymysql.connect(
        host='localhost',
        user='root',
        password='1234',
        database='banco_jornada_ademicon',
        cursorclass=pymysql.cursors.DictCursor
    )
    return connection