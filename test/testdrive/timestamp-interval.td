# Copyright Materialize, Inc. and contributors. All rights reserved.
#
# Use of this software is governed by the Business Source License
# included in the LICENSE file at the root of this repository.
#
# As of the Change Date specified in that file, in accordance with
# the Business Source License, use of this software will be governed
# by the Apache License, Version 2.0.

$ postgres-execute connection=postgres://mz_system:materialize@${testdrive.materialize-internal-sql-addr}
ALTER SYSTEM SET min_timestamp_interval = '500ms'

! CREATE SOURCE foo FROM LOAD GENERATOR COUNTER with (TIMESTAMP INTERVAL '100ms', SIZE '1')
contains:invalid timestamp interval of 100ms, must be in the range [500ms, 1000ms]

> CREATE SOURCE quick_counter FROM LOAD GENERATOR COUNTER with (TIMESTAMP INTERVAL '500ms', SIZE '1')

> SELECT c1=c2 from (SELECT COUNT(*) as c1 from quick_counter), (SELECT COUNT(*) as c2 from quick_counter)
true

$ postgres-execute connection=postgres://mz_system:materialize@${testdrive.materialize-internal-sql-addr}
ALTER SYSTEM SET max_timestamp_interval = '2s'

> CREATE SOURCE slow_counter FROM LOAD GENERATOR COUNTER with (TIMESTAMP INTERVAL '2s', SIZE '1')

> SELECT c1=c2 from (SELECT COUNT(*) as c1 from slow_counter), (SELECT COUNT(*) as c2 from slow_counter)
true

$ set schema={"type": "record", "name": "schema", "fields": [ {"name": "f1", "type": ["int", "null"]} , {"name": "f2", "type": ["int", "null"]}] }

$ kafka-create-topic topic=top1

$ kafka-ingest format=avro topic=top1 schema=${schema} timestamp=1

> CREATE CONNECTION IF NOT EXISTS csr_conn TO CONFLUENT SCHEMA REGISTRY (
    URL '${testdrive.schema-registry-url}'
  );

> CREATE CONNECTION kafka_conn
  TO KAFKA (BROKER '${testdrive.kafka-addr}', SECURITY PROTOCOL PLAINTEXT);

> CREATE SOURCE t1
  FROM KAFKA CONNECTION kafka_conn (TOPIC 'testdrive-top1-${testdrive.seed}')
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY CONNECTION csr_conn
  ENVELOPE NONE
  WITH (TIMESTAMP INTERVAL '500ms')

> DROP SOURCE quick_counter CASCADE
> DROP SOURCE slow_counter CASCADE
