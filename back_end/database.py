import pymysql

def get_db_connection():
    connection = pymysql.connect(
        host='localhost',       # ou IP do servidor MySQL
        user='root',     
        password='123',   
        database='banco_jornada_ademicon',
        cursorclass=pymysql.cursors.DictCursor
    )
    return connection
