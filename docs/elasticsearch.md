# Elasticsearch

## Setup of Elasticsearch

You'll need to standup the infrastructure required to index and visualize results.
We are using Elasticsearch as the database, and its up to the user to decide
the implementation and configuration of elasticsearch. Ripsaw will work as long
as it can index data to indices with pattern `ripsaw-{benchmark}-*`.


## Changes to CR for indexing data

`spec.elasticsearch` is where changes will need to happen in the cr to index
data to Elasticsearch.

- **server**: Host address where es is running.
- **port**: Port number that es is listening on.
> Note: `elasticsearch.Elasticsearch([_es_connection_string], send_get_body_as='POST'))` is
how we'd be creating es connection object where
`_es_connection_string = str(server) + ':' + str(port)`. This will allow for
passing in the basic auth values directly in the server definition.
- **index_name**: ES index to send the documents to.

- **cert_verify**: set to false, if and only if es is setup with ssl, but you'd
like to skip cert verification.
> Note: if ssl is not enabled, setting this to false will break as there are no
certs to skip verification of.

Additionally, the `spec.clustername` and `spec.test_user` values are
advised to be set to allow for further tagging of data.
