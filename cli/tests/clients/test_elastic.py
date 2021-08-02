from elasticmock import elasticmock
from ripsaw.clients import elastic
import elasticsearch

class TestElastic():

    @elasticmock
    def test_check_index(self):
        server = "http://localhost:9200"
        index = "test-index"
        document = {
            "uuid": "foo",
            "data": "bar"
        }

        es = elasticsearch.Elasticsearch(hosts=[{'host': 'localhost', 'port': 9200}])
        es_object = es.index(index, document)
        assert elastic.check_index(server, document['uuid'], index)
        assert not elastic.check_index(server, "random-uuid", index)


        



