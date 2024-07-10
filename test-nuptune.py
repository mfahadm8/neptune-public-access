from gremlin_python.driver import client

def create_client(endpoint):
    conn = client.Client(endpoint,'g')
    return conn
            
def run_query(conn, query):
    result = conn.submit(query)
    future_results = result.all()
    return future_results.result()

conn = create_client("wss://neptune-db.powerodd.com:8182/gremlin")
query = 'g.V().limit(1)'
results = run_query(conn, query)