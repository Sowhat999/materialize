# Copyright Materialize, Inc. and contributors. All rights reserved.
#
# Use of this software is governed by the Business Source License
# included in the LICENSE file at the root of this repository.
# As of the Change Date specified in that file, in accordance with
# the Business Source License, use of this software will be governed
# by the Apache License, Version 2.0.

$ postgres-execute connection=postgres://mz_system:materialize@${testdrive.materialize-internal-sql-addr}
ALTER SYSTEM SET enable_envelope_materialize = true

# Note these are nonsense schemas, as this error happens before schema verification of any form
$ set keyschema={}

$ set schema={}

$ kafka-create-topic topic=headers_src

> CREATE CONNECTION kafka_conn
  TO KAFKA (BROKER '${testdrive.kafka-addr}', SECURITY PROTOCOL PLAINTEXT);

! CREATE SOURCE headers_src
  FROM KAFKA CONNECTION kafka_conn (TOPIC
  'testdrive-headers_src-${testdrive.seed}')
  KEY FORMAT AVRO USING SCHEMA '${keyschema}'
  VALUE FORMAT AVRO USING SCHEMA '${schema}'
  INCLUDE HEADERS
  ENVELOPE MATERIALIZE
contains:INCLUDE <metadata> requires ENVELOPE (NONE|UPSERT|DEBEZIUM)

! CREATE SOURCE headers_src
  FROM KAFKA CONNECTION kafka_conn (TOPIC
  'testdrive-headers_src-${testdrive.seed}')
  KEY FORMAT AVRO USING SCHEMA '${keyschema}'
  VALUE FORMAT AVRO USING SCHEMA '${schema}'
  INCLUDE HEADERS
  ENVELOPE MATERIALIZE
contains:INCLUDE <metadata> requires ENVELOPE (NONE|UPSERT|DEBEZIUM)

! CREATE SOURCE headers_src
  FROM LOAD GENERATOR COUNTER
  INCLUDE HEADERS
contains:INCLUDE HEADERS with non-Kafka sources not supported
